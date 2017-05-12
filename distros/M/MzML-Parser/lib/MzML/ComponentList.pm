package MzML::ComponentList;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::Source;
use MzML::Analyzer;
use MzML::Detector;

has 'count' => (
    is  =>  'rw',
    isa =>  'Int',
    );

has 'source' => (
    is  =>  'rw',
    isa =>  'MzML::Source',
    default => sub {
        my $self = shift;
        return my $obj = MzML::Source->new();
        }
    );

has 'analyzer' => (
    is  =>  'rw',
    isa =>  'MzML::Analyzer',
    default => sub {
        my $self = shift;
        return my $obj = MzML::Analyzer->new();
        }
    );

has 'detector' => (
    is  =>  'rw',
    isa =>  'MzML::Detector',
    default => sub {
        my $self = shift;
        return my $obj = MzML::Detector->new();
        }
    );

1;
