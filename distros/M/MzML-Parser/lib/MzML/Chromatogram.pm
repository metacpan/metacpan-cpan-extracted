package MzML::Chromatogram;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::BinaryDataArrayList;
use MzML::Product;

with 'MzML::CommonParams';

has 'dataProcessingRef' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'defaultArrayLength' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'id' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'index' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'nativeID' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'precursor' => (
    is  =>  'rw',
    isa =>  'MzML::Precursor',
    default => sub {
        my $self = shift;
        return my $obj = MzML::Precursor->new();
        }
    );

has 'product' => (
    is  =>  'rw',
    isa =>  'MzML::Product',
    default => sub {
        my $self = shift;
        return my $obj = MzML::Product->new();
        }
    );

has 'binaryDataArrayList' => (
    is  =>  'rw',
    isa =>  'MzML::BinaryDataArrayList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::BinaryDataArrayList->new();
        }
    );

1;
