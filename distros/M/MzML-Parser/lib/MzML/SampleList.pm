package MzML::SampleList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'sample' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::Sample]',
    );

1;
