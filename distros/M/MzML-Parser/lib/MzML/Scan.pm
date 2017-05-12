package MzML::Scan;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::ScanWindowList;

with 'MzML::CommonParams';

has 'externalSpectrumID' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'instrumentConfigurationRef' => (
    is  =>  'rw',
    isa =>  'Str',
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
    isa =>  'MzML::ScanWindowList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::ScanWindowList->new();
        }
    );

1;
