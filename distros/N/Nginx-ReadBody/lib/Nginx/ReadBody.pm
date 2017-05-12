package Nginx::ReadBody;

use 5.008000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Nginx::ReadBody ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.07';

use nginx;

my %handlers = ( OK          => sub { return  OK; }
               ,400          => sub { return 400; }
               ,500          => sub { return 500; }
               ,'0 BUT TRUE' => sub { return '0 BUT TRUE'; }
               );

sub variable(@)
	{
	my $res = $_[0]->variable($_[1]);

	defined($res) && length($res) && return $res;

	if (defined($_[2]))
		{
		$_[3] && $_[0]->log_error(0, "read_body: variable '$_[1]' is not provided, using default".($_[3] > 0 ? " '$_[2]'" : ''));
		length($_[2]) && $_[0]->variable($_[1], $_[2]);
		return $_[2];
		};

	$_[3] && $_[0]->log_error(0, "read_body: variable '$_[1]' is not provided");

	return undef;
	};

sub handler($$$$)
	{
	my $h = variable(@_);

	defined($h) || return undef;

	defined($handlers{$h}) && return $handlers{$h};

	if ($h =~ m/^\d+$/)
		{ $handlers{$h} = eval "sub { return $h; }"; }
	elsif ($h =~ m/^\w+(?:\:\:\w+)*$/)
		{ $handlers{$h} = eval "\\&$h"; }
	elsif ($h =~ m/^\s*sub\s*[\(\{]/)
		{ $handlers{$h} = eval $h; }
	else
		{ $@ = "handler must be a digital code, method name, or a subroutine definition"; };
	
	$@ || return $handlers{$h};

	$_[0]->log_error(0, "read_body: invalid handler '$_[1]'($handlers{$h}) provided: $@");

	delete($handlers{$h});

	return $handlers{500};
	};

my $complete = sub($)
	{
	my $debug  = variable($_[0], 'read_body_debug', 0, 0);

	my $check = handler($_[0], 'read_body_check', '0 BUT TRUE', $debug);
	($check == $handlers{500}) && return 500;

	return &{$check}($_[0]) ? &{handler($_[0], 'read_body_done', 500, $debug)}($_[0]) : &{handler($_[0], 'read_body_false', 400, $debug)}($_[0])
	};

sub read($)
	{
	my $debug  = variable($_[0], 'read_body_debug', 0, 0);

	$_[0]->has_request_body($complete) && return OK;

	$debug && $_[0]->log_error(0, "read_body: no-body request");

	return &{handler($_[0], 'read_body_nodata', 400, $debug)}(@_);
	};


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 TRANSLATIONS

English: L<Nginx::ReadBody>

Russian: L<Nginx::ReadBody::Russian>

=head1 NAME

Nginx::ReadBody - nginx web server embeded perl module to read and evaluate a request body

I<Version 0.07>

=head1 SYNOPSIS

  #nginx.conf (part of)
  location /post_here {
   error_page 345 = @get_there;
   error_page 346 = @good_post;
   error_page 347 = @bad_post;

   if ($request_method != POST)
    { return 345; }

   set $read_body_debug  1;
   set $read_body_check  'My::Own::check_userdata';
   set $read_body_done   346;
   set $read_body_nodata 347;
   set $read_body_false  347;

   perl  Nginx::ReadBody::read;
   }

=head1 DESCRIPTION

nginx does not provide any methods to evaluate a request body. So this module does.

=head1 The C<Nginx::ReadBody> methods

=over 4

=item C<read($request);>

Intended to be a location handler.

=item C<handler($request, $variableName, $defaultValue, $debug)>

Handlers retriver and registrar. This method is intended to be used from other perl method acts as a location handler.

Method returns a reference to a subroutine defined by C<$variableName> (or C<$defaultValue>).

Value of  C<$variableName> is evaluated and the result is cached. See C<$variableName> for details.

Parameters are:

=over 8

=item C<$request>

nginx request object (see L<http://wiki.nginx.org/NginxEmbeddedPerlModule>).

=item C<$variableName>

Name of the C<nginx.conf> variable contains a handler definition.

Definition could be:

=over 12

=item Digital code

Evaluated to the reference to a subroutine just returning this code. Exactly like this:

    $handler = eval "sub { return $variableValue; }";

=item Name of the perl subroutine

Like C<My::Own::method>.

Evaluated to the reference to the named subroutine. Exactly like this:

    $handler = eval "\\&$variableValue";

=item Definition of the perl subroutine

Like C<"sub {...}">.

Evaluated to the reference to the defined subroutine. Exactly like this:

    $handler = eval $variableValue;

B<I did not test this option at all!> Could be dangerous with typos, etc.

=back

In case C<$variableName> value is not in any of these 3 forms or in case C<eval()> failed
reference to the subroutine always returning C<500> is returned.

=item C<$defaultValue>

Definition should be used in case a variable provided is not set or set to empty string.

=item C<$debug>

Controlls a verbosity of the messages written to the error log. See L<$read_body_debug>.

=back

=item C<variable($request, $variableName, $defaultValue, $debug)>

Smart - ok, not complitely stupid - C<nginx.conf> variable retriever. This method is intended to be used from other perl method acts as a location handler.

Parameters are:

=over 8

=item C<$request>

nginx request object (see L<http://wiki.nginx.org/NginxEmbeddedPerlModule>).

=item C<$variableName>

Name of the variable to retrieve.

=item C<$defaultValue>

Value should be used in case a variable requested is not set or set to empty string. Could be C<undef>.

In case C<$defaultValue> is not C<undef> this variable will be set to this value for the rest of the whole request.

=item C<$debug>

Controlls a verbosity of the messages written to the error log. See L<$read_body_debug>.

=back

=back

=head1 C<nginx.conf> variables controlls the C<Nginx::ReadBody> behaviour

=over 4

=item C<$read_body_debug>

Controlls should debug messages be sent to error log or not.

=over 8

=item Digit C<0> or C<''> (empty string)

B<Default>. No debug messages.

=item Digit C<1> or C<'nonEmptyString'>

Full debug info.

=item C<'0 but true'> or negative number

Less verbose debug.

=back

=item C<$read_body_nodata>

Should contain a C<handler> definition (see C<handler>).

Default is C<400>.

In case a request does not have a body this C<handler> is called.

Handler is called with a nginx request object (see L<http://wiki.nginx.org/NginxEmbeddedPerlModule>) as a single argument.

This handler should act as a location handler.

=item C<$read_body_check>

Should contain a C<handler> definition (see C<handler>).

Default is C<'0 but true'> so in case you did not define your own C<$read_body_check>
the request will be passed directly to C<$read_body_done>.

As soon as body is fully received this C<handler> is called to check the content.

Handler is called with a nginx request object (see L<http://wiki.nginx.org/NginxEmbeddedPerlModule>) as a single argument.

Should return C<TRUE> or C<FALSE>.

=item C<$read_body_done>

Should contain a C<handler> definition (see C<handler>).

Default is C<500> that should be a clear indication you did not define an action
should be performed with the request we just received a body for.

As soon as C<$read_body_check> returns C<TRUE> this C<handler> is called.

Handler is called with a nginx request object (see L<http://wiki.nginx.org/NginxEmbeddedPerlModule>) as a single argument.

This handler should act as a location handler.

=item C<$read_body_false>

Should contain a C<handler> definition (see C<handler>).

Default is C<400>.

As soon as C<$read_body_check> returns C<FALSE> this C<handler> is called.

Handler is called with a nginx request object (see L<http://wiki.nginx.org/NginxEmbeddedPerlModule>) as a single argument.

This handler should act as a location handler.

=back

=head2 EXPORT

None.

=head1 SEE ALSO

L<http://wiki.nginx.org/NginxEmbeddedPerlModule>.

=head1 AUTHOR

Daniel Podolsky, E<lt>tpaba@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Daniel Podolsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
