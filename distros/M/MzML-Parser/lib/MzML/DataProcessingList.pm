package MzML::DataProcessingList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'dataProcessing' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::DataProcessing]',
    );

1;
