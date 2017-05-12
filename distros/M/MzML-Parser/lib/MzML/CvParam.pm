package MzML::CvParam;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'accession' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'cvRef' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'name' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'unitAccession' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'unitCvRef' => (
    is  => 'rw',
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
