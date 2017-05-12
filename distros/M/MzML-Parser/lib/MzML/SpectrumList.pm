package MzML::SpectrumList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'defaultDataProcessingRef' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'spectrum' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::Spectrum]',
    );

1;
