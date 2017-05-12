package Net::GPSD3::Return::SUBFRAME;
use strict;
use warnings;
use base qw{Net::GPSD3::Return::Unknown};

our $VERSION='0.12';

=head1 NAME

Net::GPSD3::Return::SUBFRAME - Net::GPSD3 Return SUBFRAME Object

=head1 SYNOPSIS

=head1 DESCRIPTION

Provides a Perl object interface to the SUBFRAME object returned by the GPSD daemon.

An example JSON object:

=head1 METHODS PROPERTIES

=head2 class

Returns the object class

=head2 string

Returns the JSON string

=head2 parent

Return the parent Net::GPSD object

=head2 device

=cut

sub device {shift->{"device"}};

=head1 BUGS

Log on RT and Send to gpsd-dev email list

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

Try gpsd-dev email list

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  STOP, LLC
  domain=>michaelrdavis,tld=>com,account=>perl
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Net::GPSD3>, L<DateTime>, L<Net::GPSD3::Return::Unknown>

=cut

1;
