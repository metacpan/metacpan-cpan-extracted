package MzML::InstrumentConfigurationList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'instrumentConfiguration' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::InstrumentConfiguration]',
    );

1;
