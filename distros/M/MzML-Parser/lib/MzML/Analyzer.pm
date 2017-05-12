package MzML::Analyzer;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

with 'MzML::CommonParams';

has 'order' => (
    is  =>  'rw',
    isa =>  'Int',
    );

1;
