package MzML::Cv;
use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'uri' => (
    is  =>  'rw',
    isa =>  'URI',
    );

has 'fullName' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'id' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'version' => (
    is  =>  'rw',
    isa =>  'Str',
    );

1;
