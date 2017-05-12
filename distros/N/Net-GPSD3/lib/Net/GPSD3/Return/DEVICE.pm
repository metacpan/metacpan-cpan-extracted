package Net::GPSD3::Return::DEVICE;
use strict;
use warnings;
use base qw{Net::GPSD3::Return::Unknown};

our $VERSION='0.14';

=head1 NAME

Net::GPSD3::Return::DEVICE - Net::GPSD3 Return DEVICE Object

=head1 SYNOPSIS

=head1 DESCRIPTION

Provides a Perl object interface to the DEVICE object returned by the GPSD daemon.

=head1 METHODS

=head2 class

Returns the object class

=head2 string

Returns the JSON string

=head2 parent

Return the parent L<Net::GPSD3> object

=head2 device

Name the device for which the control bits are being reported, or for which they are to be applied. This attribute may be omitted only when there is exactly one subscribed channel.

=cut

sub device {shift->{"device"}};

=head2 driver

GPSD's name for the device driver type. Won't be reported before gpsd has seen identifiable packets from the device.

=cut

sub driver {shift->{"driver"}||'none'};

=head2 subtype

Whatever version information the device returned.

=cut

sub subtype {shift->{"subtype"}||'none'};

=head2 path

=cut

sub path {shift->{"path"}};

=head2 native

0 means NMEA mode and 1 means alternate mode (binary if it has one, for SiRF and Evermore chipsets in particular). Attempting to set this mode on a non-GPS device will yield an error.

=cut

sub native {shift->{"native"}};

=head2 activated

Time the device was activated, or 0 if it is being closed.

Note: I expect this to change to either a boolean or a timestamp in the 3.5 protocol.

=cut

sub activated {shift->{"activated"}};

=head2 cycle

Device cycle time in seconds.

=cut

sub cycle {shift->{"cycle"}};

=head2 mincycle

Device minimum cycle time in seconds. Reported from ?CONFIGDEV when (and only when) the rate is switchable. It is read-only and not settable.

=cut

sub mincycle {shift->{"mincycle"}};

=head2 flags

Bit vector of property flags. Currently defined flags are: describe packet types seen so far (GPS, RTCM2, RTCM3, AIS). Won't be reported if empty, e.g. before gpsd has seen identifiable packets from the device.

=cut

sub flags {shift->{"flags"}};

=head2 bps

Device speed in bits per second.

=cut

sub bps {shift->{"bps"}};

=head2 parity

N, O or E for no parity, odd, or even.

=cut

sub parity {shift->{"parity"}};

=head2 stopbits

Stop bits (1 or 2).

=cut

sub stopbits {shift->{"stopbits"}};

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

L<Net::GPSD3>

=cut

1;
