package MzML::TargetList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'target' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::Target]',
    );

1;
