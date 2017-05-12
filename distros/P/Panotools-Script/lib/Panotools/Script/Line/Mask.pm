package Panotools::Script::Line::Mask;

use strict;
use warnings;
use Panotools::Script::Line;

use vars qw /@ISA/;
@ISA = qw /Panotools::Script::Line/;

=head1 NAME

Panotools::Script::Line::Mask - Image Mask

=head1 SYNOPSIS

Optional image masks are described by a 'k' line

=head1 DESCRIPTION

  i2           Set image number this mask applies to

  t0           Type for mask:
                   0 - negative (exclude region)
                   1 - positive (include region)
                   2 - exclude region from all images in the same stack
                   3 - include region from all images in the same stack
                   4 - exclude region from all images with the same lens

  p"1262 2159 1402 2065 1468 2003"  List of node coordinates
               Coordinates are in pairs, at least three pairs are required
                 
=cut

sub _defaults
{
    my $self = shift;
}

sub _valid { return '^([itp])(.*)' }

sub Identifier
{
    my $self = shift;
    return "k";
}

sub Report
{
    my $self = shift;
    my @report;
    return [] unless defined $self->{t};
    my $type = 'Negative';
    $type = 'Positive' if $self->{t} == 1;
    my $nodes = $self->{p};
    $nodes =~ s/(^"|"$)//;
    my @nodes = split ' ', $nodes;

    push @report, ['Mask type', $type];
    push @report, ['Nodes', scalar @nodes / 2];
    [@report];
}

1;
