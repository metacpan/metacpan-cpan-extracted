package MzML::ReferenceableParamGroupRef;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'ref' => (
    is  =>  'rw',
    isa =>  'Str',
    );

1;
