package Template::Directive::XSSAudit;
use strict;
use warnings;
use base qw/ Template::Directive /;

BEGIN {
    use vars qw ($VERSION);
    $VERSION = '1.03';
}

our $DEFAULT_ERROR_HANDLER = sub {

    my $context = shift || {};

    warn __PACKAGE__->event_parameter_to_string(
        $context,
        'on_error'
    ) . "\n";

};
our $DEFAULT_OK_HANDLER   = sub { };

our @DEFAULT_GOOD_FILTERS = qw( html uri );

my $_error_handler = $DEFAULT_ERROR_HANDLER;
my $_ok_handler    = $DEFAULT_OK_HANDLER;
my @_good_filters  = @DEFAULT_GOOD_FILTERS;


my $_line_info      = '';
my @checking_get    = ();
my @applied_filters = ();
my $latest_ident    = '';

=head1 NAME

Template::Directive::XSSAudit - TT2 output filtering lint testing

=head1 SYNOPSIS

  use Template;
  use Template::Directive::XSSAudit;

  my $tt = Template->new({
      FACTORY => "Template::Directive::XSSAudit"
  });

  my $input = <<'END';
  Hello [% exploitable.goodness %] World!
  How would you like to [% play.it.safe | html %] today?
  END

  my $out  = '';
  $tt->process(\$input, {}, \$out) || die $tt->error();

  # output on STDOUT... via default on_error handler
  # see the documentation of on_error for explanation of the
  # output format of the default error handler
  #input file   NO_FILTERS  line:1    exploitable.goodness

=head1 DESCRIPTION

This module will help you perform basic lint tests of your template toolkit
files. 

It is intended to parse through all GET items, and make sure that at least
one "good" filter is used to escape it.

A callback may be provided so that the errors may be handled in a way that
makes sense for the project at hand.  See C<on_error> for more details.

There is another callback which can be provided named C<on_filtered>. This is
triggered when a variable is successfully filtered.  By default there is
no implementation.  See C<on_filtered> for more details.

Additionally, a list of filter names may be provided, instructing the module
to require that certain filters be used for output escaping in the tests.

Have a look at the t/*.t files that come with the distribution as they
leverage the C<on_error()> callback routine.

=head1 IMPORTANT NOTES ON SECURITY

This tool is NOT a substitude for code and security reviews as it is NOT
context aware. This means if you use a html filter in javascript context
or css context or html attribute context, you would not be escaping things
properly and this tool would not catch that.  

You also need to make sure that your "good" filters are actually doing their
job and escaping things properly.

All of this to say, don't let this give you a false sense of security.

=head1 EXPORTS

None.

=head1 METHODS

=over 4

=item Template::Directive::XSSAudit->on_error ( [ coderef ] )

This method is called on every variable involved in a template
toolkit 'GET' which was not filtered properly. 

The callback will be executed in one of two cases:

 - The variable in question has NO output filtering
 - The variable is filtered but none of the filters 
   were found in the C<good_filter> list.

A default implementation is provided which will simply C<warn> any
problems which are found with the following information (tab delimited):

  <file_name> <error_type> line:<line_no> <filters used csv>

If you call this method without a subroutine reference, it will simply
return you the current implementation.

If you provide your own callback, it will be passed one parameter 
which is a hash reference containing the following keys.

=over 4

=item variable_name

This is a string represending the variable name which was found to be
incorrectly escaped.

=item filtered_by

This will contain an array reference containing the names of the filters which
were applied to the variable name.

If there are entries in this list, it means that no filter in the
good filter list was found to apply to the variable.  See C<good_filter> for
more information.

In the case of variables with no filters, this will be an empty array
reference.

=item file_name

The line number in the template file where the problem occurred.

This is parsed out as best as can be done but it may come back as an empty
string in many cases.  It is a convenience item and should not be relied on
for any sort of automation.

=item file_line

The line number in the template file where the problem occurred.

This is parsed out as best as can be done but it may come back as an empty
string in many cases.  It is a convenience item and should not be relied on
for any sort of automation.

=back

=back

=cut

sub on_error {
    my $class = shift;
    my ($callback) = @_;
    if( $callback ) {
        if( ref($callback) ne "CODE" ) {
            croak("argument to on_error must be a subroutine reference"); 
        }
        $_error_handler = $callback;
    }
    return $_error_handler;
}

=over 4

=item Template::Directive::XSSAudit->on_filtered ( [ coderef ] )

This method is called on every variable involved in a template
toolkit 'GET' which was filtered satisfactorily. 

By default, no implementation is given so if you want this to
do anything, you'll have to provide a coderef yourself.

The callback and function works just like C<on_error> so see the
documentation for that method for more details.

=back

=cut

sub on_filtered {
    my $class = shift;
    my ($callback) = @_;
    if( $callback ) {
        if( ref($callback) ne "CODE" ) {
            croak("argument to on_filtered must be a subroutine reference"); 
        }
        $_ok_handler = $callback;
    }
    return $_ok_handler;
    
}

sub event_parameter_to_string {
    my $class = shift;
    my($context, $event) = @_;

    my $var_name     = $context->{variable_name};
    my $filters      = $context->{filtered_by};
    my $file         = $context->{file_name} || '<unknown_file>';
    my $line_no      = $context->{file_line} || 0;

    my $problem_type = $event eq "on_filtered" ? "OK"
                       : @$filters             ? "NO_SAFE_FILTER"
                       :                         "NO_FILTERS";
    my $used_filters = @$filters ? "\t" . (join ",", @$filters) : "";

    return sprintf("%s\t%s\tline:%d\t%s%s",
        $file, $problem_type, $line_no, $var_name, $used_filters
    )
}

=over 4

=item Template::Directive::XSSAudit->good_filters ( [ arrayref ] )

This method will return the current list of "good" filters to you
as an array reference. eg.

  [ 'html', 'uri' ]

If you pass an array reference of strings, it will also set the list of good
filters.  The defaults are simply 'html' and 'uri' but I will be adding more
int the future.

=back

=cut

sub good_filters {
    my $class     = shift;
    my ($array_ref) = @_;
    if($array_ref) {
        if( ref($array_ref) ne "ARRAY" ) {
            croak("argument to good_filters must be an array reference");
        }
        @_good_filters = @$array_ref;
    }
    return \@_good_filters;
}

# ================================================
# ========= Template::Directive overrides ========
# ================================================

sub get {
    my $class = shift;

    my $result = $class->SUPER::get(@_);
    $_line_info = _parse_line_info($result);
    _trigger_warnings();

    if( $_[0] =~ /stash->get/ ) {
        @checking_get = @_;
    }

    return $result;
}

sub filter {
    my $class = shift;
    if( @checking_get ) {
        (my $filter = $_[0][0][0]) =~ s/'//g;
        push @applied_filters, $filter
    }

    my $result = $class->SUPER::filter(@_);
    $_line_info = _parse_line_info($result);
    return $result;
}


sub ident {
    my $class = shift;
    if(!@checking_get) {
        # TODO: recursive pattern matching on perl expressions
        # of the form:
        # $stash->get([ date, 0, format, 0 [ $stash->get([date, 0, now, 0]), %Y/%m/%d ]
        # take a look at this for inspiration:
        # http://perldoc.perl.org/perlfaq6.html#Can-I-use-Perl-regular-expressions-to-match-balanced-text%3F
        $latest_ident = join '.', grep { "$_" ne "0" } @{$_[0]};
        $latest_ident =~ s/'//g;
    }
    my $result = $class->SUPER::ident(@_);
    $_line_info = _parse_line_info($result);
    return $result;
}

# 'block' is notably and intentionally missing
my @TRIGGER_END_OF_GET_SUBS = qw/
anon_block textblock text quoted assign
filenames call set default insert include process if
foreach next wrapper multi_wrapper while switch try
throw clear break return stop use view perl no_perl rawperl
capture macro debug template /;
for my $method (@TRIGGER_END_OF_GET_SUBS) {
    no strict;
    *$method = sub {
        my $class = shift;
        my $result = &{"Template::Directive::$method"}("Template::Directive",@_);
        $_line_info = _parse_line_info($result);
        _trigger_warnings();
        return $result;
    }
}

## INTERNAL
sub _parse_line_info {
    my $text = shift;
    if( $text =~ /^(#line.*)$/m ) {
        return $1;
    }
    return $_line_info;
}

sub _trigger_warnings {
    if( @checking_get ) {
        my @good_filters;
        if(@applied_filters) {
            my (%union, %isect);
            foreach my $e (@applied_filters, @{good_filters()}) {
                $union{$e}++ && $isect{$e}++
            }
            @good_filters = keys %isect;

        }

        $_line_info =~ /#line\s+(\d+)\s+"(.+?)"/;
        my($file_line,$file_name) = ($1, $2); 
        my $event_sub = !@good_filters ? on_error() : on_filtered();
        $event_sub->({
            variable_name => $latest_ident,
            filtered_by   => [ @applied_filters ],
            file_name => $file_name,
            file_line => $file_line,
        });

        $_line_info      = '';
        $latest_ident    = '';
        @applied_filters = ();
        @checking_get    = ();
    }
}


1;
__END__

=head1 SEE ALSO

L<Template>
L<http://github.com/captin411/template-directive-xssaudit/>
L<http://www.owasp.org/index.php/Category:OWASP_Encoding_Project/>
L<http://ha.ckers.org/xss.html>

=head1 BUGS

Please report bugs using the CPAN Request Tracker at L<http://rt.cpan.org/>

=head1 AUTHOR

David Bartle <dbartle@mediatemple.net>

This work was sponsored by my employer, (mt) Media Temple, Inc.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with
this module.

=cut
