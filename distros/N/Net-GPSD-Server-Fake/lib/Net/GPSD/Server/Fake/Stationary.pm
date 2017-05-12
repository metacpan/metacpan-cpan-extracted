package Net::GPSD::Server::Fake::Stationary;

=pod

=head1 NAME

Net::GPSD::Server::Fake::Stationary - Provides a stationery feed for the GPSD Daemon. 

=head1 SYNOPSIS

  use Net::GPSD::Server::Fake;
  use Net::GPSD::Server::Fake::Stationary;
  my $server=Net::GPSD::Server::Fake->new();
  my $provider =
       Net::GPSD::Server::Fake::Stationary->new(lat=>38.865826,  #degrees
                                                lon=>-77.108574, #degrees
                                                speed=>25,       #m/s
                                                heading=>90,     #degrees
                                                alt=>50,         #meters
                                                tlefile=>"./gps.tle");
  $server->start($provider);

=head1 DESCRIPTION

=cut

use strict;
use vars qw($VERSION);
use GPS::SpaceTrack;

$VERSION = sprintf("%d.%02d", q{Revision: 0.16} =~ /(\d+)\.(\d+)/);

=head1 CONSTRUCTOR

=head2 new

Returns a new provider that can be passed to Net::GPSD::Server::Fake.

  my $provider=Net::GPSD::Server::Fake::Stationary->new();

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
  $self->{'lat'}     = $param{'lat'}       ||  39.5;
  $self->{'lon'}     = $param{'lon'}       || -77.5;
  $self->{'speed'}   = $param{'speed'}     ||  0;
  $self->{'heading'} = $param{'heading'}   ||  0;
  $self->{'alt'}     = $param{'alt'}       ||  0;
  $self->{'tlefile'} = $param{'tlefile'};
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
  my $time=shift()||time;
  my $pt0=shift()||undef();

  use Net::GPSD::Point;
  my $point=Net::GPSD::Point->new($pt0);
  $point->tag("FAKE");
  $point->time($time);
  $point->lat($self->{'lat'});
  $point->lon($self->{'lon'});
  $point->speed($self->{'speed'});
  $point->heading($self->{'heading'});
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

Net::GPSD

=cut
