package Net::GPSD::Server::Fake::Track;

=pod

=head1 NAME

Net::GPSD::Server::Fake::Track - Provides a linear feed for the GPSD Daemon.

=head1 SYNOPSIS

 use Net::GPSD::Server::Fake;
 use Net::GPSD::Server::Fake::Track;
 my $server=Net::GPSD::Server::Fake->new();
 my $provider=Net::GPSD::Server::Fake::Track->new(lat=>38.865826,
                                                  lon=>-77.108574,
                                                  speed=>25,
                                                  heading=>45.3,
                                                  alt=>23.4,
                                                  tle=>$filename);
 $server->start($provider);

=head1 DESCRIPTION

=cut

use strict;
use vars qw($VERSION);
use GPS::SpaceTrack;
use Geo::Forward;
use Net::GPSD::Point;
use Net::GPSD::Satellite;

$VERSION = sprintf("%d.%02d", q{Revision: 0.16} =~ /(\d+)\.(\d+)/);

=head1 CONSTRUCTOR

=head2 new

Returns a new provider that can be passed to Net::GPSD::Server::Fake.

 my $provider=Net::GPSD::Server::Fake::Track->new();

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
  $self->{'lat'}    =$param{'lat'}      ||  39.5;
  $self->{'lon'}    =$param{'lon'}      || -77.5;
  $self->{'speed'}  =$param{'speed'}    ||  20;
  $self->{'heading'}=$param{'heading'}  ||  0;
  $self->{'alt'}    =$param{'alt'}      ||  0;
  $self->{'tlefile'}=$param{'tlefile'};
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

  my $object = Geo::Forward->new();
  my $lat;
  my $lon;
  my $faz;
  my $baz;
  my $speed;
  my $lasttime;
  if (ref($pt0) eq "Net::GPSD::Point") {
    $lat=$pt0->lat;
    $lon=$pt0->lon;
    $faz=$pt0->heading;
    $speed=$pt0->speed;
    $lasttime=$pt0->time;
  } else {
    $lat=$self->{'lat'};
    $lon=$self->{'lon'};
    $faz=$self->{'heading'};
    $speed=$self->{'speed'};
    $lasttime=undef();
  }
  if (defined $lasttime) {
    my $dist=$speed * ($time-$lasttime);
    ($lat,$lon,$baz)=$object->forward($lat,$lon,$faz,$dist);
    #print "Heading: $faz\n";
    $faz=$baz-180;
  }
  my $point=Net::GPSD::Point->new();
  $point->tag("FAKE");
  $point->time($time);
  $point->errortime(0.001);
  $point->lat($lat);
  $point->lon($lon);
  $point->speed($speed);
  #print ", FAZ: $faz";
  $point->heading($faz);
  $point->alt($self->{'alt'});
  $point->mode(3);
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
  if (defined $obj) {
    my $lat=$point->lat;
    my $lon=$point->lon;
    my $alt=$point->alt||0;
    my $time=$point->time;
    #print "Lat => $lat, Lon => $lon, ALT => $alt, Time => $time\n";
    my @list=grep {$_->snr > 0} $obj->getsatellitelist({lat=>$lat, lon=>$lon,
                                                       alt=>$alt, time=>$time});
    pop @list until scalar(@list) <= 12;
    return wantarray ? @list : \@list;
  } else {
    my $obj=Net::GPSD::Satellite->new(0,0,0,0,0);
    return wantarray ? ($obj) : [$obj];
  }
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

Net::GPSD

=cut
