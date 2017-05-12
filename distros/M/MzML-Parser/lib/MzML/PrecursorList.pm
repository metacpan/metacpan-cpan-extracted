package MzML::PrecursorList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'precursor' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::Precursor]',
    );

1;

