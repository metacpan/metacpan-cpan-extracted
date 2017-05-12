package MzML::InstrumentConfiguration;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::ComponentList;
use MzML::SoftwareRef;

with 'MzML::CommonParams';

has 'id' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'componentList' => (
    is  =>  'rw',
    isa =>  'MzML::ComponentList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::ComponentList->new();
        }
    );

has 'softwareRef' => (
    is  =>  'rw',
    isa =>  'MzML::SoftwareRef',
    default => sub {
        my $self = shift;
        return my $obj = MzML::SoftwareRef->new();
        }
    );

1;
