package MzML::Spectrum;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::ScanList;
use MzML::PrecursorList;
use MzML::ProductList;
use MzML::BinaryDataArrayList;

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

has 'sourceFileRef' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'spotID' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'scanList' => (
    is  =>  'rw',
    isa =>  'MzML::ScanList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::ScanList->new();
        }
    );

has 'precursorList' => (
    is  =>  'rw',
    isa =>  'MzML::PrecursorList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::PrecursorList->new();
        }
    );

has 'productList' => (
    is  =>  'rw',
    isa =>  'MzML::ProductList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::ProductList->new();
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
