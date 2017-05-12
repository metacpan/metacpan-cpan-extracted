package Strava::GPX;

use strict;
use warnings;

our $VERSION = 0.01;

use LWP::UserAgent;
use Geo::Gpx;

sub new {
  my ($class, $url) = @_;

  $url = URI->new($url);

  my $ua = LWP::UserAgent->new;
  my $res = $ua->get($url);

  die unless $res->code == 200;

#        {
# distance: [0.0,..],
# altitude: [1868.6,..],
# elevLow: 1812.0,
# elevHigh: 2130.6,
# latlng: [[ 1.1, 2.2],[..,..]]

  my %self;
  bless \%self, $class;
  my ($latlng) = $res->content =~ m/CourseMap.*?latlng:\s(\S+)\,/s;

  $self{latlng} = eval $latlng;

  return \%self;
}

sub to_gpx {
    my $self = shift;

    my $gpx = Geo::Gpx->new;
    my @points;
    foreach my $latlng ( @{$self->{latlng}} ) {
        push @points, { lat => $latlng->[0], lon => $latlng->[1] };
    }
    my $tracks = [ { name => $self->{url},
        segments => [ { points => \@points, } ], } ];
    $gpx->tracks($tracks);

    return $gpx->xml( '1.0' );
}

__END__

=head1 NAME

Strava::GPX - Get a gpx file from a strava ride

=head1 SYNOPSIS

  use Strava::GPX;
  my $strava = Strava::GPX->new( $url );
  my $gpx = $strava->to_gpx; # gpx file content

=head1 DESCRIPTION

Grab a Strava page, find a course, output a gpx file so you can go ride it.

=head1 SEE ALSO

Strava::Utilities

=head1 AUTHOR

Fred Moyer, E<lt>fred@redhotpenguin.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Fred Moyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
