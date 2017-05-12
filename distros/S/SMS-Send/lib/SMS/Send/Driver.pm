package SMS::Send::Driver;

=pod

=head1 NAME

SMS::Send::Driver - Base class for SMS::Send drivers

=head1 DESCRIPTION

The C<SMS::Send::Driver> class provides an abstract base class for all
L<SMS::Send> driver classes.

At this time it does not provide any implementation code for drivers
(although this may change in the future) with the exception of some
methods provided to trigger "does not implement method" errors.

However, it does serve as something you should sub-class your driver from
to identify it as a L<SMS::Send> driver.

Please note that if your driver class not B<not> return true for
C<$driver->isa('SMS::Send::Driver')> then the L<SMS::Send> constructor
will refuse to use your class as a driver.

=head1 METHODS

=cut

use 5.006;
use strict;
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.06';
}

=pod

=head2 new

The C<new> constructor is required to be implemented by your driver subclass.

It recieves a set of arbitrary paired params. The values of these params are
assumed to be driver-specific (this is expected to change).

If your driver will need to login to some system, locate hardware, or
do some other form of initialisation to validate the SMS delivery mechanism
exists, it should do so in C<new>.

Should return a new L<SMS::Send::Driver>-subclass object, or die on error.

=cut

sub new {
	my $class = shift;
	Carp::croak("Driver Error: $class does not implement the 'new' constructor");
}

=pod

=head2 send_sms

The C<send_sms> method is required to be implemented by your driver subclass.

It recieves a set of param pairs as documented in L<SMS::Send>.

Should return true for either success or fire-and-forget with unknown result,
defined-but-false ('' or 0) for a failed message send, or die on a fatal error.

=cut

sub send_sms {
	my $class = ref($_[0]) || $_[0];
	Carp::croak("Driver Error: $class does not implement the 'send_sms' method");
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
