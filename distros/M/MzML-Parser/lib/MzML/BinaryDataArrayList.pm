package MzML::BinaryDataArrayList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'binaryDataArray' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::BinaryDataArray]',
    );

1;
