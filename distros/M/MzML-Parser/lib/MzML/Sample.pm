package MzML::Sample;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

with 'MzML::CommonParams';

has 'id' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'name' => (
    is  =>  'rw',
    isa =>  'Str',
    );

1;
