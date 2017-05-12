package MzML::SourceFileList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'sourceFile' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::SourceFile]',
    );

1;
