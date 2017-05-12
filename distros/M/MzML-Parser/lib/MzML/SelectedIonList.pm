package MzML::SelectedIonList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'selectedIon' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::SelectedIon]',
    );

1;
