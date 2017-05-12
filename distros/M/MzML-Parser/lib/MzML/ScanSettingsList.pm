package MzML::ScanSettingsList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'scanSettings' => (
    is  =>  'rw',
    isa =>  'ArrayRef[MzML::ScanSettings]',
    );

1;
