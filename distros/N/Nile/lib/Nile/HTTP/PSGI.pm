#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::HTTP::PSGI;

use strict;
use 5.008_001;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

use base qw(CGI::Simple);

if ($CGI::Simple::VERSION lt '1.111') {
    no warnings 'redefine';
    *CGI::Simple::_internal_read = sub($\$;$) {
        my ($self, $buffer, $len) = @_;
        $len = 4096 if !defined $len;
        if (exists $self->{psgi_env}->{'psgi.input'}) {
            $self->{psgi_env}->{'psgi.input'}->read($$buffer, $len);
        }
        elsif ( $self->{'.mod_perl'} ) {
            my $r = $self->_mod_perl_request();
            $r->read( $$buffer, $len );
        }
        else {
            read STDIN, $$buffer, $len;
        }
    };
}

sub new {
    my ($class, $env) = @_;

    my $self = bless {
        psgi_env => $env,
        use_tempfile => 1,
    }, $class;

    local *ENV = $env;

    $self->_initialize_globals;
    $self->_store_globals;
    
    no strict 'refs';
    $self->_read_parse($self->{psgi_env}->{'psgi.input'});

    $self;
}

sub _mod_perl { return 0 }

sub env {
    $_[0]->{psgi_env};
}

# copied and rearanged from CGI::Simple::header
sub psgi_header {
    my($self, @p) = @_;
    require CGI::Simple::Util;
    my @header;
    my(
        $type, $status, $cookie, $target, $expires, $nph, $charset,
        $attachment, $p3p, @other
    ) = CGI::Simple::Util::rearrange([
        ['TYPE', 'CONTENT_TYPE', 'CONTENT-TYPE'],
        'STATUS', ['COOKIE', 'COOKIES'], 'TARGET',
        'EXPIRES', 'NPH', 'CHARSET',
        'ATTACHMENT','P3P',
    ], @p);

    $type ||= 'text/html' unless defined($type);
    if (defined $charset) {
        $self->charset($charset);
    } else {
        $charset = $self->charset if $type =~ /^text\//;
    }
    $charset ||= '';

    # rearrange() was designed for the HTML portion, so we
    # need to fix it up a little.
    my @other_headers;
    for (@other) {
        # Don't use \s because of perl bug 21951
        next unless my($header,$value) = /([^ \r\n\t=]+)=\"?(.+?)\"?$/;
        $header =~ s/^(\w)(.*)/"\u$1\L$2"/e;
        push @other_headers, $header, $self->unescapeHTML($value);
    }

    $type .= "; charset=$charset"
        if     $type ne ''
           and $type !~ /\bcharset\b/
           and defined $charset
           and $charset ne '';

    # Maybe future compatibility.  Maybe not.
    my $protocol = $self->{psgi_env}->{SERVER_PROTOCOL} || 'HTTP/1.0';

    push @header, "Status", $status if $status;
    push @header, "Window-Target", $target if $target;
    if ($p3p) {
        $p3p = join ' ',@$p3p if ref $p3p eq 'ARRAY';
        push @header, "P3P", qq{policyref="/w3c/p3p.xml", CP="$p3p"};
    }

    # push all the cookies -- there may be several
    if ($cookie) {
        my(@cookie) = ref $cookie eq 'ARRAY' ? @{$cookie} : $cookie;
        for (@cookie) {
            my $cs = eval{ $_->can('as_string') } ? $_->as_string : "$_";
            push @header, "Set-Cookie", $cs if $cs ne '';
        }
    }
    # if the user indicates an expiration time, then we need
    # both an Expires and a Date header (so that the browser is
    # uses OUR clock)
    $expires = 'now'
      if $self->no_cache;    # encourage no caching via expires now
    push @header, 'Expires', CGI::Simple::Util::expires($expires, 'http')
      if $expires;
    push @header, 'Date', CGI::Simple::Util::expires(0, 'http')
      if defined $expires || $cookie || $nph;
    push @header, 'Pragma', 'no-cache' if $self->cache or $self->no_cache;
    push @header, 'Content-Disposition', "attachment; filename=\"$attachment\""
      if $attachment;
    push @header, @other;
    push @header, 'Content-Type', $type if $type;

    $status ||= "200";
    $status =~ s/\D*$//;

    return $status, \@header;
}

# The list is auto generated and modified with:
# perl -nle '/^sub (\w+)/ and $sub=$1; \
#   /^}\s*$/ and do { print $sub if $code{$sub} =~ /([\%\$]ENV|http\()/; undef $sub };\
#   $code{$sub} .= "$_\n" if $sub; \
#   /^\s*package [^C]/ and exit' \
# `perldoc -l CGI`
for my $method (qw(
    url_param
    upload
    upload_info
    parse_query_string
    cookie
    raw_cookie
    header
    MyFullUrl
    PrintEnv
    auth_type
    content_length
    content_type
    document_root
    gateway_interface
    path_translated
    referer
    remote_addr
    remote_host
    remote_ident
    remote_user
    request_method
    #script_name
    server_name
    server_port
    server_protocol
    server_software
    user_name
    user_agent
    virtual_host
    path_info
    accept
    http
    https
    protocol
    #url
)) {
    no strict 'refs';
    *$method = sub {
        my $self  = shift;
        my $super = "SUPER::$method";
        local *ENV = $self->{psgi_env};
        return $self->$super(@_);
    };
}

sub script_name {
    my ($self) = @_;
    #$ENV{'SCRIPT_NAME'} || $0 || '' 
    $self->env->{SCRIPT_NAME} || '' 
}

sub url {
    my ( $self, @p ) = @_;
    use CGI::Simple::Util 'rearrange';
    my ( $relative, $absolute, $full, $path_info, $query, $base )
    = rearrange(
        [
          'RELATIVE', 'ABSOLUTE', 'FULL',
          [ 'PATH',  'PATH_INFO' ],
          [ 'QUERY', 'QUERY_STRING' ], 'BASE'
        ],
        @p
    );

    my $url;

    local *ENV = $self->{psgi_env};

    $full++ if $base || !( $relative || $absolute );

    my $path = $self->path_info;

    my $script_name = $self->script_name;

    if ($full) {
        my $protocol = $self->protocol();
        $url = "$protocol://";
        my $vh = $self->http( 'host' );

        if ($vh) {
            $url .= $vh;
        }
        else {
            $url .= server_name();
            my $port = $self->server_port;
            $url .= ":" . $port
            unless ( lc( $protocol ) eq 'http' && $port == 80 )
                    or ( lc( $protocol ) eq 'https' && $port == 443 );
        }

        return $url if $base;
        #$url .= $script_name;
        #$url .= $path;
    }
    elsif ($relative) {
        ($url) = $script_name =~ m#([^/]+)$#;
    }
    elsif ($absolute) {
        #$url = $script_name;
        $url = $path;
    }

    $url .= $path if $path_info and defined $path;
    $url .= "?" . $self->query_string if $query and $self->query_string;
    $url = '' unless defined $url;

    $url    =~ s/([^a-zA-Z0-9_.%;&?\/\\:+=~-])/uc sprintf("%%%02x",ord($1))/eg;

    return $url;
}

sub DESTROY {
    my $self = shift;
    CGI::Simple::_initialize_globals();
}

1;

__END__

=head1 NAME

Nile::HTTP::PSGI - Enable your CGI::Simple aware applications to adapt PSGI protocol

=head1 VERSION

0.001_002

=head1 SYNOPSIS

  use Nile::HTTP::PSGI;

  sub app {
      my $env = shift;
      # set CGI::Simple's global control variables
      local $CGI::Simple::DISABLE_UPLOADS = 0;    # enable upload
      local $CGI::Simple::POST_MAX = 1024;        # max size on POST
      my $q = Nile::HTTP::PSGI->new($env);
      return [ $q->psgi_header, [ $body ] ];
  }

=head1 DESCRIPTION

This module extends L<CGI::Simple> to use in some web applications
under the PSGI servers. This is a experimental branch from L<CGI::PSGI>
module for L<CGI> by Tatsuhiko Miyagawa.

=head1 AUTHOR

MIZUTANI Tociyuki C<< tociyuki@google.com >>.
Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Nile> L<CGI::Simple> L<CGI::PSGI>

=cut

