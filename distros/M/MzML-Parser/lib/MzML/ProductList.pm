package MzML::ProductList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'product' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::Product]',
    );

1;
