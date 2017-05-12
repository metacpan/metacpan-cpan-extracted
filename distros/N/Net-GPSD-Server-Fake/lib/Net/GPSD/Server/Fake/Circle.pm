package Net::GPSD::Server::Fake::Circle;

=pod

=head1 NAME

Net::GPSD::Server::Fake::Circle - Provides a linear feed for the GPSD Daemon.

=head1 SYNOPSIS

  use Net::GPSD::Server::Fake;
  use Net::GPSD::Server::Fake::Circle;
  my $server=Net::GPSD::Server::Fake->new();
  my $provider=Net::GPSD::Server::Fake::Circle->new(lat=>38.865826, #center
                                                    lon=>-77.108574,#center
                                                    speed=>25,      #constant
                                                    heading=>45.3,  #init
                                                    distance=>1000);#constant
  $server->start($provider);

=head1 DESCRIPTION

=cut

use strict;
use vars qw($VERSION);
use Geo::Functions qw{deg_rad};
use GPS::SpaceTrack;

$VERSION = sprintf("%d.%02d", q{Revision: 0.16} =~ /(\d+)\.(\d+)/);

=head1 CONSTRUCTOR

=head2 new

Returns a new provider that can be passed to Net::GPSD::Server::Fake.

  my $provider=Net::GPSD::Server::Fake::Circle->new();

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=cut

sub initialize {
  my $self = shift();
  my %param = @_;
  $self->{'lat'}      = $param{'lat'}       ||  39.5  ; #degrees
  $self->{'lon'}      = $param{'lon'}       || -77.5  ; #degrees
  $self->{'speed'}    = $param{'speed'}     ||  20    ; #m/s
  $self->{'heading'}  = $param{'heading'}   ||  0     ; #degrees
  $self->{'distance'} = $param{'distance'}  ||  1000  ; #meters
  $self->{'tlefile'}  = $param{'tlefile'};
}

=head2 tle

Method to create and retrieve the TLE object.

=cut

sub tle {
  my $self=shift();
  unless (defined($self->{'tle'})) {
    $self->{'tle'}=GPS::SpaceTrack->new(filename=>$self->{'tlefile'})
      || die("Error: Cannot create GPS::SpaceTrack object.");
  }
  return $self->{'tle'};
}

=head2 get

Returns a Net::GPSD::Point object

  my $point=$obj->get;

=cut

sub get {
  my $self=shift();
  my $time=shift();
  my $pt0=shift();

  use Geo::Forward;
  use Net::GPSD::Point;
  my $object = Geo::Forward->new();
  my $lat=$self->{'lat'};
  my $lon=$self->{'lon'};
  my $speed=$self->{'speed'};
  my $dist=$self->{'distance'};
  my $lasttime;
  my $da;
  my $alpha;

  if (ref($pt0) eq "Net::GPSD::Point") {
    $lasttime=$pt0->time;
    $da=deg_rad(($time-$lasttime)*$speed/$dist);
    $alpha=$pt0->heading+90-$da;
  } else {
    $da=0;
    $alpha=$self->{'heading'}+90-$da;
    $lasttime=undef();
  }
  my $faz=$alpha;
  my ($lat1,$lon1,$baz) = $object->forward($lat,$lon,$faz,$dist);
  my $heading=$baz+90;
  $heading-=360 if $heading>=360;

  my $point=Net::GPSD::Point->new();
  $point->tag("FAKE");
  $point->time($time);
  $point->errortime(0.001);
  $point->lat($lat1);
  $point->lon($lon1);
  $point->speed($speed);
  $point->heading($heading);
  $point->mode(2);
  $point->status(1);

  return $point;
}

=head2 getsatellitelist

Returns a list of Net::GPSD::Satellite objects

  my @list=$obj->getsatellitelist($point);

=cut

sub getsatellitelist {
  my $self=shift();
  my $point=shift();
  my $obj=$self->tle;
  my $lat=$point->lat;
  my $lon=$point->lon;
  my $hae=$point->alt;
  my $time=$point->time;
  my @list=grep {$_->snr > 0} $obj->getsatellitelist({lat=>$lat, lon=>$lon,
                                                      alt=>$hae, time=>$time});
  pop @list until scalar(@list) <= 12;
  return defined($obj) ? @list : undef();
}

1;

__END__

=head1 GETTING STARTED

=head1 KNOWN LIMITATIONS

=head1 BUGS

=head1 EXAMPLES

=head1 AUTHOR

Michael R. Davis, qw/gpsd michaelrdavis com/

=head1 LICENSE

Copyright (c) 2006 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Net:GPSD

=cut
