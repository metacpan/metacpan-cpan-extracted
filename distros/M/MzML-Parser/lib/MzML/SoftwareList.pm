package MzML::SoftwareList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'software' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::Software]',
    );

1;
