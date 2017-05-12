package Net::GPSD3::Return::Satellite;
use strict;
use warnings;
use base qw{Net::GPSD3::Return::Unknown};

our $VERSION='0.13';

=head1 NAME

Net::GPSD3::Return::Satellite - Net::GPSD3 Return Satellite Object

=head1 SYNOPSIS

  use Net::GPSD3 0.13;
  my $gpsd = Net::GPSD3->new;
  my $poll = $gpsd->poll;  #new method in 0.12
  my $sky  = $poll->sky;   #new method in 0.13
  printf "Reported: %s, Used: %s\n", $sky->reported, $sky->used;
  printf "PRN: %s\n", join(", ", map {$_->used ? $_->prn : "-".$_->prn} $sky->Satellites);

=head1 DESCRIPTION

Provides a Perl object interface to the Satellite data structure returned by the GPSD daemon.

An example JSON string:

  {"PRN":15,"el":77,"az":123,"ss":0, "used":false},

=head1 METHODS

=head2 class

Returns the object class

=head2 string

Returns the JSON string

=head2 parent

Return the parent Net::GPSD object

=head2 PRN, prn

Returns the GPS Satellites Pseudo Random Number Identifier

=cut

sub PRN {shift->{"PRN"}};

*prn=\&PRN;

=head2 used

Returns a L<JSON::XS::Boolean> true or false object.

=cut

sub used {shift->{"used"}};

=head2 az, azimuth

Returns the azimuth, degrees from true north.

=cut

sub az {shift->{"az"}};

*azimuth=\&az;

=head2 el, elevation

Returns the Elevation in degrees.

=cut

sub el {shift->{"el"}};

*elevation=\&el;

=head2 ss

Signal strength in dBHz.

Note: C/N0 is dBHz usually, but trimbles can also emit poorly specified Amplitude Measurement Units. 

=cut

sub ss {shift->{"ss"}};

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

L<Net::GPSD3>, L<Net::GPSD3::Return::Unknown>

=cut

1;
