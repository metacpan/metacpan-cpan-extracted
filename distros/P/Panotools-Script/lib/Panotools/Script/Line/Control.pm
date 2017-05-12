package Panotools::Script::Line::Control;

use strict;
use warnings;
use Math::Trig;
use Panotools::Script::Line;

use vars qw /@ISA/;
@ISA = qw /Panotools::Script::Line/;

=head1 NAME

Panotools::Script::Line::Control - Panotools control-point

=head1 SYNOPSIS

A pair of control-points forms a 'c' line

=head1 DESCRIPTION

One line per point pair.
about one pair of points per image per variable being optimized.
The more variables being optimized the more control points needed.

  n0           first image
  N1           second image
  x1066.5      first image x point position
  y844.333     first image y point position
  X239.52      second image x point position
  Y804.64      second image y point position
  t0           type of control point (optional)
                 0 - normal (default)
                 1 - optimize horizontally only
                 2 - optimize vertically only
                 3+ (all other numbers) - straight line

=cut

sub _defaults
{
    my $self = shift;
}

sub _valid { return '^([nNxXyYt])(.*)' }

sub Identifier
{
    my $self = shift;
    return "c";
}

=pod

Get a simplified description of a control point useful for identifying
duplicates like so:

  print $point->Packed;

Format is first image, x, y, second image, x, y, point type

e.g: 2,123,456,3,234,567,0

=cut

sub Packed
{
    my $self = shift;
    if ($self->{n} < $self->{N})
    {
        return join ',', $self->{n}, int ($self->{x}), int ($self->{y}),
                         $self->{N}, int ($self->{X}), int ($self->{Y}), $self->{t};
    }
    else
    {
        return join ',', $self->{N}, int ($self->{X}), int ($self->{Y}),
                         $self->{n}, int ($self->{x}), int ($self->{y}), $self->{t};
    }
}

=pod

Get a value for control point error distance (measured in pixels in the panorama
output):

  print $point->Distance ($pto);

Note that it is necessary to pass a Panotools::Script object to this method.
Note also that the values returned are approximately half those returned by
panotools itself, go figure.

=cut

sub Distance
{
    my $self = shift;
    my $p = shift;

    my $image_N = $p->Image->[$self->{N}];
    my $image_n = $p->Image->[$self->{n}];

    my $vec_N = $image_N->To_Cartesian ($p, [$self->{X},$self->{Y}]);
    my $vec_n = $image_n->To_Cartesian ($p, [$self->{x},$self->{y}]);

    $vec_N = _normalise ($vec_N);
    $vec_n = _normalise ($vec_n);

    my $angle = acos (($vec_N->[0]->[0] * $vec_n->[0]->[0])
                    + ($vec_N->[1]->[0] * $vec_n->[1]->[0])
                    + ($vec_N->[2]->[0] * $vec_n->[2]->[0]));

    if ($p->Panorama->{f} == 0) # special case for rectilinear output
    {
        my $radius = $p->Panorama->{w} / 2 / tan (deg2rad ($p->Panorama->{v}/2));
        return $radius * $angle;
    }

    return $angle / pi() * $p->Panorama->{w} / 2;
}

sub _normalise
{
    my $vector = shift;

    my $magnitude = _magnitude ($vector->[0]->[0], $vector->[1]->[0], $vector->[2]->[0]);

    $vector->[0]->[0] = $vector->[0]->[0] / $magnitude;
    $vector->[1]->[0] = $vector->[1]->[0] / $magnitude;
    $vector->[2]->[0] = $vector->[2]->[0] / $magnitude;

    return $vector;
}

sub _magnitude
{
    my ($x, $y, $z) = @_;
    sqrt ($x*$x + $y*$y + $z*$z);
}

1;

