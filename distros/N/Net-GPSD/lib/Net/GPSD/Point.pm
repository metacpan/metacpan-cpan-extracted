package Net::GPSD::Point;
use strict;
use warnings;
use Geo::Functions qw{knots_mps mps_knots};

our $VERSION='0.39';

=head1 NAME

Net::GPSD::Point - Provides an object interface for a gps point.

=head1 SYNOPSIS

  use Net::GPSD;
  $obj=Net::GPSD->new(host=>"localhost",
                      port=>"2947");
  my $point=$obj->get;           #$point is a Net::GPSD::Point object
  print $point->latlon. "\n";    #use a "." here to force latlon to a scalar

or to use Net::GPSD::Point objects in you own code.

  use Net::GPSD::Point;
  my $point=Net::GPSD::Point->new();
  $point->lat(39.5432524);
  $point->lon(-77.243532);
  print $point->latlon. "\n";

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new

  my $point=Net::GPSD::Point->new();

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=head2 initialize

=cut

sub initialize {
  my $self = shift();
  my $data = shift();
  foreach (keys %$data) {
    $self->{$_}=[@{$data->{$_}}]; #there has got to be a better way to do this...
  }
}

=head2 fix

Returns true if mode is fixed (logic based on the gpsd M[0] or O[14])

  my $fix=$point->fix;

=cut

sub fix {
  my $self = shift();
  return defined($self->status)
           ? ($self->status > 0 ? 1 : 0)
           : (defined($self->mode)
                ? ($self->mode > 1 ? 1 : 0)
                : 0);
}

=head2 status

Returns DGPS status. (maps to gpsd S command first data element)

  my $status=$point->status;

=cut

sub status {
  my $self = shift();
  if (@_) { $self->{'S'}->[0] = shift() } #sets value
  return q2u $self->{'S'}->[0];
}

=head2 datetime

Returns datetime. (maps to gpsd D command first data element)

  my $datetime=$point->datetime;

=cut

sub datetime {
  my $self = shift();
  if (@_) { $self->{'D'}->[0] = shift() } #sets value
  return q2u $self->{'D'}->[0];
}

=head2 tag

Returns a tag identifying the last sentence received.  (maps to gpsd O command first data element)

  my $tag=$point->tag;

=cut

sub tag {
  my $self = shift();
  if (@_) { $self->{'O'}->[0] = shift() } #sets value
  return q2u $self->{'O'}->[0];
}

=head2 time

Returns seconds since the Unix epoch, UTC. May have a fractional part. (maps to gpsd O command second data element)

  my $time=$point->time;

=cut

sub time {
  my $self = shift();
  if (@_) { $self->{'O'}->[1] = shift() } #sets value
  return q2u $self->{'O'}->[1];
}

=head2 errortime

Returns estimated timestamp error (%f, seconds, 95% confidence). (maps to gpsd O command third data element)

  my $errortime=$point->errortime;

=cut

sub errortime {
  my $self = shift();
  if (@_) { $self->{'O'}->[2] = shift() } #sets value
  return q2u $self->{'O'}->[2];
}

=head2 latitude aka lat

Returns Latitude as in the P report (%f, degrees). (maps to gpsd O command fourth data element)

  my $lat=$point->lat;
  my $lat=$point->latitude;

=cut

sub latitude {
  my $self = shift();
  if (@_) { $self->{'O'}->[3] = shift() } #sets value
  return q2u $self->{'O'}->[3];
}

sub lat {
  my $self = shift();
  return $self->latitude(@_);
}

=head2 longitude aka lon

Returns Longitude as in the P report (%f, degrees). (maps to gpsd O command fifth data element)

  my $lon=$point->lon;
  my $lon=$point->longitude;

=cut

sub longitude {
  my $self = shift();
  if (@_) { $self->{'O'}->[4] = shift() } #sets value
  return q2u $self->{'O'}->[4];
}

sub lon {
  my $self = shift();
  return $self->longitude(@_);
}

=head2 latlon

Returns Latitude, Longitude as an array in array context and as a space joined string in scalar context

  my @latlon=$point->latlon;
  my $latlon=$point->latlon;

=cut

sub latlon {
  my $self = shift();
  my @latlon=($self->latitude, $self->longitude);
  return wantarray ? @latlon : join(" ", @latlon);
}

=head2 altitude aka alt

Returns the current altitude, meters above mean sea level. (maps to gpsd O command sixth data element)

  my $alt=$point->alt;
  my $alt=$point->altitude;

=cut

sub altitude {
  my $self = shift();
  if (@_) { $self->{'O'}->[5] = shift() } #sets value
  return q2u $self->{'O'}->[5];
}

sub alt {
  my $self = shift();
  return $self->altitude(@_);
}

=head2 errorhorizontal

Returns Horizontal error estimate as in the E report (%f, meters). (maps to gpsd O command seventh data element)

  my $errorhorizontal=$point->errorhorizontal;

=cut

sub errorhorizontal {
  my $self = shift();
  if (@_) { $self->{'O'}->[6] = shift() } #sets value
  return q2u $self->{'O'}->[6];
}

=head2 errorvertical

Returns Vertical error estimate as in the E report (%f, meters). (maps to gpsd O command eighth data element)

  my $errorvertical=$point->errorvertical;

=cut

sub errorvertical {
  my $self = shift();
  if (@_) { $self->{'O'}->[7] = shift() } #sets value
  return q2u $self->{'O'}->[7];
}

=head2 heading

Returns Track as in the T report (%f, degrees). (maps to gpsd O command ninth data element)

  my $heading=$point->heading;

=cut

sub heading {
  my $self = shift();
  if (@_) { $self->{'O'}->[8] = shift() } #sets value
  return q2u $self->{'O'}->[8];
}

=head2 speed

Returns speed (%f, meters/sec). Note: older versions of the O command reported this field in knots. (maps to gpsd O command tenth data element)

  my $speed=$point->speed;

=cut

sub speed {
  my $self = shift();
  if (@_) { $self->{'O'}->[9] = shift() } #sets value
  return q2u $self->{'O'}->[9];
}

=head2 speed_knots

Returns speed in knots

  my $speed=$point->speed_knots;

=cut

sub speed_knots {
  my $self = shift();
  if (@_) { $self->{'O'}->[9] = mps_knots(shift()) } #sets value
  return defined($self->speed) ? knots_mps($self->speed) : undef();
}

=head2 climb

Returns Vertical velocity as in the U report (%f, meters/sec). (maps to gpsd O command 11th data element)

  my $climb=$point->climb;

=cut

sub climb {
  my $self = shift();
  if (@_) { $self->{'O'}->[10] = shift() } #sets value
  return q2u $self->{'O'}->[10];
}

=head2 errorheading

Returns Error estimate for course (%f, degrees, 95% confidence). (maps to gpsd O command 12th data element)

  my $errorheading=$point->errorheading;

=cut

sub errorheading {
  my $self = shift();
  if (@_) { $self->{'O'}->[11] = shift() } #sets value
  return q2u $self->{'O'}->[11];
}

=head2 errorspeed

Returns Error estimate for speed (%f, meters/sec, 95% confidence). Note: older versions of the O command reported this field in knots. (maps to gpsd O command 13th data element)

  my $errorspeed=$point->errorspeed;

=cut

sub errorspeed {
  my $self = shift();
  if (@_) { $self->{'O'}->[12] = shift() } #sets value
  return q2u $self->{'O'}->[12];
}

=head2 errorclimb

Returns Estimated error for climb/sink (%f, meters/sec, 95% confidence). (maps to gpsd O command 14th data element)

  my $errorclimb=$point->errorclimb;

=cut

sub errorclimb {
  my $self = shift();
  if (@_) { $self->{'O'}->[13] = shift() } #sets value
  return q2u $self->{'O'}->[13];
}

=head2 mode

Returns The NMEA mode. 0=no mode value yet seen, 1=no fix, 2=2D (no altitude), 3=3D (with altitude). (maps to gpsd M command first data element)

  my $mode=$point->mode;

=cut

sub mode {
  my $self = shift();
  if (@_) { $self->{'M'}->[0] = $self->{'O'}->[14] = shift() } #sets value
  return q2u(defined($self->{'O'}->[14]) ? $self->{'O'}->[14] : $self->{'M'}->[0]);
}

=head2 q2u

=cut

sub q2u {
  my $a=shift();
  return defined($a) ? ($a eq '?' ? undef() : $a) : undef();
}

1;

__END__

=head1 LIMITATIONS

The object allows users to set values for each method but, most likely, this is not what most users will want.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 BUGS

Email to author and submit to RT.

=head1 EXAMPLES

=head1 AUTHOR

Michael R. Davis, qw/gpsd michaelrdavis com/

=head1 LICENSE

Copyright (c) 2006 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Geo::Point>, L<Net::GPSD>

=cut
