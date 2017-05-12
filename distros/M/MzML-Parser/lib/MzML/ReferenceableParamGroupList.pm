package MzML::ReferenceableParamGroupList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'referenceableParamGroup' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::ReferenceableParamGroup]',
    );

1;
