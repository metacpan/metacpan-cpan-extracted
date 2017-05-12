package MzML::AquisitionSettingsList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' = (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'aquisitionSettings' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::AquisitionSettings]',
    );

1;

