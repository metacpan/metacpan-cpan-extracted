package MzML::SourceFileRefList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'sourceFileRef' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::SourceFileRef]',
    );

1;
