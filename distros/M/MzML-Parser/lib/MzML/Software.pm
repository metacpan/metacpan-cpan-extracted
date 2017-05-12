package MzML::Software;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::SoftwareParam;

with 'MzML::CommonParams';

has 'id' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'version' => (
    is  =>  'rw',
    isa =>  'Str',
    );

1;
