package MzML::ScanSettings;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::SourceFileRefList;
use MzML::TargetList;

with 'MzML::CommonParams';

has 'id' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'sourceFileRefList' => (
    is  =>  'rw',
    isa =>  'MzML::SourceFileRefList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::SourceFileRefList->new();
        }
    );

has 'targetList' => (
    is  =>  'rw',
    isa =>  'MzML::TargetList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::TargetList->new();
        }
    );

1;
