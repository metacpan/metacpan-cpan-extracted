package MzML::SoftwareParam;

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

has 'version' => (
    is  =>  'rw',
    isa =>  'Str',
    );

1;
