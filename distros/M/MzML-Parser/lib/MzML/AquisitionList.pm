package MzML::AquisitionList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

with 'MzML::CommonParams';

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'aquisition' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::Aquisition]',
    );

1;
