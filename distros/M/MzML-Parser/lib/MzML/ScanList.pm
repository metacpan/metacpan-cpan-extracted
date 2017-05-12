package MzML::ScanList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

with 'MzML::CommonParams';

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'scan' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::Scan]',
    );

1;
