package MzML::UserParam;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'name' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'type' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'unitAccession' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'unitCvRef' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'unitName' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'value' => (
    is  =>  'rw',
    isa =>  'Str',
    );

1;
