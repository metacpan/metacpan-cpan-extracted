package MzML::ChromatogramList;

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

has 'chromatogram' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::Chromatogram]',
    );

1;
