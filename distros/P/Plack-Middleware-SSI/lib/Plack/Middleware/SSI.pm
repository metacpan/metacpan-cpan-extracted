package Plack::Middleware::SSI;

=head1 NAME

Plack::Middleware::SSI - PSGI middleware for server side include content

=head1 VERSION

0.14

=head1 DESCRIPTION

Will try to handle HTML with server side include directives as well as doing
what L<Plack::Middleware> does for "regular files".

=head1 SUPPORTED SSI DIRECTIVES

See L<http://httpd.apache.org/docs/2.0/mod/mod_include.html>,
L<http://httpd.apache.org/docs/2.0/howto/ssi.html> or
L<http://en.wikipedia.org/wiki/Server_Side_Includes> for more details.

=head2 set

    <!--#set var="SOME_VAR" value="123" -->

=head2 echo

    <!--#echo var="SOME_VAR" -->

=head2 config

    <!--#config timefmt="..." -->
    <!--#config errmsg="..." -->

=head2 exec

    <!--#exec cmd="ls -l" -->

=head2 flastmod

    <!--#flastmod virtual="index.html" -->

=head2 fsize

    <!--#fsize file="script.pl" -->

=head2 include

    <!--#include virtual="relative/to/root.txt" -->
    <!--#include file="/path/to/file/on/disk.txt" -->

=head1 SUPPORTED SSI VARIABLES

=head2 Standard variables

DATE_GMT, DATE_LOCAL, DOCUMENT_NAME, DOCUMENT_URI, LAST_MODIFIED and
QUERY_STRING_UNESCAPED.

=head2 Extended by this module

Any variable defined in L<Plack> C<$env> will be avaiable in the SSI
document. Even so, it is not recommended to use any of those, since
it may not be compatible with Apache and friends.

=head1 SYNOPSIS

    $app = builder { enable 'SSI'; $app };

See L<Plack::Middleware> for more details.

=cut

use strict;
use warnings;
use File::Basename;
use POSIX ();
use HTTP::Date;
use HTTP::Request;
use HTTP::Response;
use HTTP::Message::PSGI;
use constant DEBUG => $ENV{'PLACK_SSI_TRACE'} ? 1 : 0;

use base 'Plack::Middleware';

our $VERSION = '0.14';

my $DEFAULT_ERRMSG = '[an error occurred while processing this directive]';
my $DEFAULT_TIMEFMT = '%A, %d-%b-%Y %H:%M:%S %Z';
my $ANON = 'Plack::Middleware::SSI::__ANON__';
my $SKIP = '__________SKIP__________';
my $CONFIG = '__________CONFIG__________';
my $BUF = '__________BUF__________';

=head1 METHODS

=head2 call

Returns a callback which can expand chunks of HTML with SSI directives
to a complete HTML document.

=cut

sub call {
    my($self, $env) = @_;

    return $self->response_cb($self->app->($env), sub {
        my $res = shift;
        my $headers = Plack::Util::headers($res->[1]);
        my $content_type = $headers->get('Content-Type') || '';

        if($content_type =~ m{^text/} or $content_type =~ m{^application/x(?:ht)?ml\b}) {
            my $buf = '';
            my $ssi_variables = {
                %$env,
                LAST_MODIFIED_TS => HTTP::Date::str2time($headers->get('Last-Modified') || ''),
                DOCUMENT_NAME => basename($env->{'PATH_INFO'}),
                DOCUMENT_URI => $env->{'REQUEST_URI'} || '',
                QUERY_STRING_UNESCAPED => $env->{'QUERY_STRING'} || '',
                $BUF => \$buf,
            };

            return sub { $self->_parse_ssi_chunk($ssi_variables, @_) };
        }

        return;
    });
}

# will match partial expression at end of string
my $SSI_EXPRESSION = qr{
     <         (?:\z| # accept end-of-string after each character
     !         (?:\z|
     -         (?:\z|
     -         (?:\z|
     \#        (?:\z|
     (.*?) \s* (?:\z| # this capture contains the actual expression
     -         (?:\z|
     -         (?:\z|
    (>)               # this capture serves as a flag that we reached end-of-expr
    ))))))))
}sx;

sub _parse_ssi_chunk {
    my($self, $ssi_variables, $chunk) = @_;
    my $buf = $ssi_variables->{$BUF};
    my $out = \do { my $tmp = '' };

    unless(defined $chunk) {
        return $$buf if(delete $ssi_variables->{$BUF}); # return the rest of buffer
        return; # ...before EOF
    }

    $$buf .= $chunk;

    my $do_keep_buffer;

    while(my($expression, $is_complete) = $$buf =~ $SSI_EXPRESSION) {
        $$out .= substr $$buf, 0, $-[0] unless($ssi_variables->{$SKIP});
        $$buf  = substr $$buf, $is_complete ? $+[0] : $-[0];

        # matched incompletely at end of string,
        # will need more chunks to finish the expression
        $do_keep_buffer = 1, last if not $is_complete;

        my $method = $expression =~ s/^(\w+)// ? "_ssi_exp_$1" : '_ssi_exp_unknown';
        my $value = $self->can($method)
            ? $self->$method($expression, $ssi_variables)
            : $ssi_variables->{$CONFIG}{'errmsg'} || $DEFAULT_ERRMSG;

        $$out .= $value unless($ssi_variables->{$SKIP});
    }

    if(not $do_keep_buffer) {
        length $$out ? ($$out .= $$buf) : ($out = $buf) # swap when possible, append if necessary
            unless($ssi_variables->{$SKIP});
        $ssi_variables->{$BUF} = \do { my $tmp = '' };
    }

    return $$out;
}

#=============================================================================
# SSI expression parsers

sub _ssi_exp_set {
    my($self, $expression, $ssi_variables) = @_;
    my $name = $expression =~ /var="([^"]+)"/ ? $1 : undef;
    my $value = $expression =~ /value="([^"]*)"/ ? $1 : '';

    if(defined $name) {
        $ssi_variables->{$name} = $value;
    }
    else {
        warn "Found SSI set expression, but no variable name ($expression)" if DEBUG;
    }

    return '';
}

sub _ssi_exp_echo {
    my($self, $expression, $ssi_variables) = @_;
    my($name) = $expression =~ /var="([^"]+)"/ ? $1 : undef;

    if(defined $name) {
        return $ANON->__eval_condition("\$$name", $ssi_variables);
    }

    warn "Found SSI echo expression, but no variable name ($expression)" if DEBUG;
    return '';
}

sub _ssi_exp_config {
    my($self, $expression, $ssi_variables) = @_;
    my($key, $value) = $expression =~ /(\w+)="([^"]*)"/ ? ($1, $2) : ();

    if(defined $key) {
        $ssi_variables->{$CONFIG}{$key} = $value;
    }

    return '';
}

sub _ssi_exp_exec {
    my($self, $expression, $ssi_variables) = @_;
    my($cmd) = $expression =~ /cmd="([^"]+)"/ ? $1 : undef;

    if(defined $cmd) {
        return join '', qx{$cmd};
    }

    warn "Found SSI cmd expression, but no command ($expression)" if DEBUG;
    return '';
}

sub _ssi_exp_fsize {
    my($self, $expression, $ssi_variables) = @_;
    my $file = $self->_expression_to_file($expression) or return '';

    return (stat $file->{'name'})[7] || '';
}

sub _ssi_exp_flastmod {
    my($self, $expression, $ssi_variables) = @_;
    my $file = $self->_expression_to_file($expression) or return '';
    my $fmt = $ssi_variables->{$CONFIG}{'timefmt'} || $DEFAULT_TIMEFMT;

    return POSIX::strftime($fmt, localtime +(stat $file->{'name'})[9]) || '';
}

sub _ssi_exp_include {
    my($self, $expression, $ssi_variables) = @_;
    my $file = $self->_expression_to_file($expression, $ssi_variables) or return '';
    my $buf = '';
    my $text = '';

    local $ssi_variables->{'DOCUMENT_NAME'} = basename $file->{'name'};
    local $ssi_variables->{'LAST_MODIFIED_TS'} = $file->{'mtime'};
    local $ssi_variables->{$BUF} = \$buf;

    while(my $line = readline $file->{'filehandle'}) {
        $text .= $self->_parse_ssi_chunk($ssi_variables, $line);
    }

    # get the rest
    $text .= $self->_parse_ssi_chunk($ssi_variables);

    return $text;
}

sub _ssi_exp_if { $_[0]->_evaluate_if_elif_else($_[1], $_[2]) }
sub _ssi_exp_elif { $_[0]->_evaluate_if_elif_else($_[1], $_[2]) }
sub _ssi_exp_else { $_[0]->_evaluate_if_elif_else('expr="1"', $_[2]) }

sub _evaluate_if_elif_else {
    my($self, $expression, $ssi_variables) = @_;
    my $condition = $expression =~ /expr="([^"]+)"/ ? $1 : undef;

    unless(defined $condition) {
        warn "Found SSI if expression, but no expression ($expression)" if DEBUG;
        return '';
    }

    if(defined $ssi_variables->{$SKIP} and $ssi_variables->{$SKIP} != 1) {
        $ssi_variables->{$SKIP} = 2; # previously true
    }
    elsif($ANON->__eval_condition($condition, $ssi_variables)) {
        $ssi_variables->{$SKIP} = 0; # true
    }
    else {
        $ssi_variables->{$SKIP} = 1; # false
    }

    return '';
}

sub _ssi_exp_endif {
    my($self, $expression, $ssi_variables) = @_;
    delete $ssi_variables->{$SKIP};
    return '';
}

sub _expression_to_file {
    my($self, $expression, $ssi_variables) = @_;

    if($expression =~ /file="([^"]+)"/) {
        my $file = $1;
        if(open my $FH, '<', $file) {
            return { name => $file, filehandle => $FH };
        }
    }
    elsif($expression =~ /virtual="([^"]+)"/) {
        my $file = $1;

        my @hdrs = map {
            $_ => $ssi_variables->{"HTTP_$_"}
        } grep {
            s/^(HTTP_)//
        } keys %$ssi_variables;

        my $request = HTTP::Request->new(GET => $file, \@hdrs);
        my $response;

        $request->uri->scheme('http') unless(defined $request->uri->scheme);
        $request->uri->host('localhost') unless(defined $request->uri->host);
        $response = HTTP::Response->from_psgi( $self->app->($request->to_psgi) );

        if($response->code == 200) {
            open my $FH, '<', \$response->content;
            return { name => $file, filehandle => $FH };
        }
    }

    warn "Could not find file from SSI expression ($expression)" if DEBUG;
    return;
}

#=============================================================================
# INTERNAL FUNCTIONS

sub __readline {
    my($buf, $FH) = @_;
    my $tmp = readline $FH;
    return unless(defined $tmp);
    $$buf .= $tmp;
    return 1;
}

=head1 COPYRIGHT & LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Henning Thorsen C<< jhthorsen at cpan.org >>

=cut


package # hide from CPAN
    Plack::Middleware::SSI::__ANON__;

my $pkg = __PACKAGE__;

sub __eval_condition {
    my($class, $expression, $ssi_variables) = @_;

    no strict;

    if($expression =~ /\$/) { # 1 is always true. do not need variables to figure that out
        my $fmt = $ssi_variables->{$CONFIG}{'timefmt'} || $DEFAULT_TIMEFMT;

        $ssi_variables->{"__{$fmt}__DATE_GMT"} ||= do { local $_ = POSIX::strftime($fmt, gmtime); $_ };
        $ssi_variables->{"__{$fmt}__DATE_LOCAL"} ||= POSIX::strftime($fmt, localtime);
        $ssi_variables->{'DATE_GMT'} = $ssi_variables->{"__{$fmt}__DATE_GMT"};
        $ssi_variables->{'DATE_LOCAL'} = $ssi_variables->{"__{$fmt}__DATE_LOCAL"};

        if(my $mtime = $ssi_variables->{'LAST_MODIFIED_TS'}) {
            $ssi_variables->{'LAST_MODIFIED'} = POSIX::strftime($fmt, localtime $mtime);
        }

        for my $key (keys %{"$pkg\::"}) {
            next if($key eq '__eval_condition');
            delete ${"$pkg\::"}{$key};
        }
        for my $key (keys %$ssi_variables) {
            next if($key eq '__eval_condition');
            *{"$pkg\::$key"} = \$ssi_variables->{$key};
        }
    }

    warn "eval ($expression)" if Plack::Middleware::SSI::DEBUG;

    if(my $res = eval $expression) {
        return $res;
    }
    if($@) {
        warn $@;
    }

    return '';
}

1;
