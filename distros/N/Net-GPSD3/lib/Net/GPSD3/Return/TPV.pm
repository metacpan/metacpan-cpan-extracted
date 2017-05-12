package Net::GPSD3::Return::TPV;
use strict;
use warnings;
use base qw{Net::GPSD3::Return::Unknown::Timestamp};
use GPS::Point;

our $VERSION='0.12';

=head1 NAME

Net::GPSD3::Return::TPV - Net::GPSD3 Return TPV Object

=head1 SYNOPSIS

  printf "Time: %s, Lat: %s, Lon: %s\n", $object->time, $object->lat, $object->lon;

=head1 DESCRIPTION

Provides a Perl object interface to the Time-Velocity-Position (TVP) object returned by the GPSD daemon.

Example JSON objects:

=head3 Protocol 3.1 Versions

  {
    "class":"TPV",
    "tag":"MID2",
    "device":"/dev/ttyUSB0",
    "time":1253593085.470,
    "ept":0.005,
    "lat":38.88945123,
    "lon":-77.03522143,
    "track":171.7249,
    "speed":0.467,
    "mode":2
  }

  {
    "class":"TPV",
    "tag":"MID2",
    "device":"/dev/ttyUSB0",
    "time":1253593667.430,
    "ept":0.005,
    "lat":38.88945123,
    "lon":-77.03522143,
    "alt":146.911,
    "track":180.0000,
    "speed":0.194,
    "climb":-0.157,
    "mode":3
  }

=head3 Protocol 3.4 Version

  {
    "class":"TPV",
    "tag":"0x0106",
    "device":"/dev/cuaU0",
    "time":"2011-03-20T06:51:59.12Z",
    "ept":0.005,
    "lat":37.371427205,
    "lon":-122.015179890,
    "alt":25.789,
    "epx":1.926,
    "epy":1.808,
    "epv":6.497,
    "track":0.0000,
    "speed":0.000,
    "climb":0.000,
    "eps":3.85,
    "mode":3
  }

=head1 METHODS PROPERTIES

=head2 class

Returns the object class

=head2 string

Returns the JSON string

=head2 parent

Return the parent Net::GPSD object

=head2 device

Name of originating device.

=cut

sub device {shift->{"device"}};

=head2 tag

Type tag associated with this GPS sentence; from an NMEA device this is just the NMEA sentence type.

=cut

sub tag {shift->{"tag"}};

=head2 mode

NMEA mode: %d, 0=no mode value yet seen, 1=no fix, 2=2D, 3=3D.

=cut

sub mode {shift->{"mode"}};

=head2 time

Seconds since the Unix epoch, UTC.  The value may have a fractional part of up to .01sec precision.

Note: In 2.96 (protocol 3.4) the TPV->time format changed from unix epoch to W3C, but this method hides that from the user.

=head2 timestamp

W3C formated timestamp value either directly from the protocol >= 3.4 or calculated < 3.4.  The value may have a fractional part of up to .01sec precision.

Note: I expect that in protocol 3.5 the value will be passed directly as TPV->timestamp

=head2 datetime

Returns a L<DateTime> object

=head2 lat

Latitude in degrees: +/- signifies West/East

=cut

sub lat {shift->{"lat"}};

=head2 lon

Longitude in degrees: +/- signifies North/South.

=cut

sub lon {shift->{"lon"}};

=head2 alt

Altitude in meters.

=cut

sub alt {shift->{"alt"}};

=head2 speed

Speed over ground, meters per second.

=cut

sub speed {shift->{"speed"}};

=head2 track

Course over ground, degrees from true north.

=cut

sub track {shift->{"track"}};

=head2 climb

Climb (postive) or sink (negative) rate, meters per second.

=cut

sub climb {shift->{"climb"}};

=head2 ept

Estimated timestamp error (%f, seconds, 95% confidence).

=cut

sub ept {shift->{"ept"}};

=head2 epx

=cut

sub epx {shift->{"epx"}};

=head2 epy

Latitude error estimate in meters, 95% confidence.

=cut

sub epy {shift->{"epy"}};

=head2 epv

Estimated vertical error in meters, 95% confidence.

=cut

sub epv {shift->{"epv"}};

=head2 eps

Speed error estimate in meters/sec, 95% confifdence.

=cut

sub eps {shift->{"eps"}};

=head2 epd

Direction error estinmate in degrees, 95% confifdence.

=cut

sub epd {shift->{"epd"}};

=head2 epc

Climb/sink error estinmate in meters/sec, 95% confifdence.

=cut

sub epc {shift->{"epc"}};

=head1 METHODS VALUE ADDED

=head2 point

Returns a L<GPS::Point> Object

=cut

sub point {
  my $self=shift;
  unless (defined($self->{"point"})) {
    $self->{"point"}=GPS::Point->new(
         time        => $self->datetime->hires_epoch, #float seconds from the unix epoch
         timestamp   => $self->timestamp,             #not yet supported but I'm planning it
         datetime    => $self->datetime,              #not yet supported but I'm planning it
         lat         => $self->lat,     #signed degrees
         lon         => $self->lon,     #signed degrees
         alt         => $self->alt,     #meters above the WGS-84 ellipsoid
         speed       => $self->speed,   #meters/second (over ground)
         heading     => $self->track,   #degrees clockwise from North
         climb       => $self->climb,   #meters/second
         etime       => $self->ept,     #float seconds
         ehorizontal => $self->epx,     #float meters
         evertical   => $self->epv,     #float meters
         espeed      => $self->eps,     #meters/second
         eheading    => $self->epd,     #degrees
         eclimb      => $self->epc,     #meters/second
         mode        => $self->mode,    #GPS mode [?=>undef,None=>1,2D=>2,3D=>3]
         tag         => $self->tag,     #Name of the GPS message for data
                                    );
  }
  return $self->{"point"};
}

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

L<Net::GPSD3>, L<GPS::Point>, L<Net::GPSD3::Return::Unknown>

=cut

1;
