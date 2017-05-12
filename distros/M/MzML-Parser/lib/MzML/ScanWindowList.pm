package MzML::ScanWindowList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'scanWindow' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::ScanWindow]',
    );

1;
