package Panotools::Script::Line::Option;

use strict;
use warnings;

=head1 NAME

Panotools::Script::Line::Option - Hugin Options

=head1 SYNOPSIS

Option parameters are described by a line beginning with '#hugin_'

=head1 DESCRIPTION

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class;
    my $self = bless {}, $class;
    $self->_defaults;
    return $self;
}

sub _defaults
{
    my $self = shift;
    %{$self} = 
       (optimizeReferenceImage => 0,
        blender => 'enblend',
        remapper => 'nona',
        enblendOptions => '',
        enfuseOptions => '',
        hdrmergeOptions => '',
        outputLDRBlended => 'true',
        outputLDRLayers => 'false',
        outputLDRExposureRemapped => 'false',
        outputLDRExposureLayers => 'false',
        outputLDRExposureBlended => 'false',
        outputHDRBlended => 'false',
        outputHDRLayers => 'false',
        outputHDRStacks => 'false',
        outputLayersCompression => 'PACKBITS',
        outputImageType => 'tif',
        outputImageTypeCompression => 'NONE',
        outputJPEGQuality => 100,
        outputImageTypeHDR => 'exr',
        outputImageTypeHDRCompression => '');
}

sub Identifier
{
    my $self = shift;
    return "#hugin_";
}

sub Parse
{
    my $self = shift;
    my $string = shift || return 0;
    my ($key, $value) = $string =~ /^#hugin_([[:alnum:]]+) *(.*)/g;
    $self->{$key} = $value;
    return 1;
}

sub Assemble
{
    my $self = shift;
    my @items;
    for my $entry (sort keys %{$self})
    {
        push @items, $self->Identifier . $entry .' '. $self->{$entry};
    }
    return (join "\n", @items) ."\n" if (@items);
    return '';
}

sub Report
{
    my $self = shift;
    my @report;
    for my $entry (sort keys %{$self})
    {
        push @report, [$entry, $self->{$entry}]
            unless ($self->{$entry} =~ /^(false)? *$/i);
    }
    [@report];
}


1;
