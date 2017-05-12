package MzML::Aquisition;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::scanWindowList;

with 'MzML::CommonParams';

has 'externalNativeID' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'externalSpectrumID' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'instrumentConfigurationRef' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'number' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'sourceFileRef' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'spectrumRef' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'scanWindowList' => (
    is  =>  'rw',
    isa =>  'MzML::scanWindowList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::scanWindowList->new();
        }
    );

1;
