package MzML::BinaryDataArray;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

with 'MzML::CommonParams';

has 'arrayLength' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'dataProcessingRef' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'encodedLength' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'binary' => (
    is  =>  'rw',
    isa =>  'Str',
    );

1;

