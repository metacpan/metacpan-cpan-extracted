package Panotools::Script::Line::Mode;

use strict;
use warnings;
use Panotools::Script::Line;

use vars qw /@ISA/;
@ISA = qw /Panotools::Script::Line/;

=head1 NAME

Panotools::Script::Line::Mode - Panotools stitching mode

=head1 SYNOPSIS

Optional stitching modes are described by an 'm' line

=head1 DESCRIPTION

  m i2

  g2.5         Set gamma value for internal computations (default 1.0)
                   See <http://www.fh-furtwangen.de/~dersch/gamma/gamma.html>
                This is especially useful in conjunction with the vignetting correction
                by division

  i2           Set interpolator, See <http://www.fh-furtwangen.de/~dersch/interpolator/interpolator.html>
                 one of:
                    0 - poly3 (default)
                    1 - spline16,
                    2 - spline36,
                    3 - sinc256,
                    4 - spline64,
                    5 - bilinear,
                    6 - nearest neighbor,
                    7 - sinc1024

   m2           Huber Sigma

   p0.001       Photometric Huber Sigma

   s1           Photometric Symmetric Error

=cut

sub _defaults
{
    my $self = shift;
    $self->{g} = 1.0;
    $self->{i} = 0;
    $self->{m} = 2;
    $self->{p} = 0.00784314;
}

sub _valid { return '^([fgimps])(.*)' }

sub Identifier
{
    my $self = shift;
    return "m";
}

sub Report
{
    my $self = shift;
    my @report;

    my $interpolator = 'UNKNOWN';
    $interpolator = 'poly3' if $self->{i} == 0;
    $interpolator = 'spline16' if $self->{i} == 1;
    $interpolator = 'spline36' if $self->{i} == 2;
    $interpolator = 'sinc256' if $self->{i} == 3;
    $interpolator = 'spline64' if $self->{i} == 4;
    $interpolator = 'bilinear' if $self->{i} == 5;
    $interpolator = 'nearest neighbor' if $self->{i} == 6;
    $interpolator = 'sinc1024' if $self->{i} == 7;

    push @report, ['Gamma', $self->{g}] if defined $self->{g};
    push @report, ['Interpolator', $interpolator] if defined $self->{i};
    push @report, ['Huber Sigma', $self->{m}] if defined $self->{m};
    push @report, ['Photometric Huber Sigma', $self->{p}] if defined $self->{p};
    push @report, ['Photometric Symmetric Error', $self->{s}] if defined $self->{s};
    [@report];
}

1;
