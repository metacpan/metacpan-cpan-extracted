package MzML::DataProcessing;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::SoftwareRef;

has 'id' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'processingMethod' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::ProcessingMethod]',
    );

1;
