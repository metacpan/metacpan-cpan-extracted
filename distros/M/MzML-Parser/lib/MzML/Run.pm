package MzML::Run;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::SourceFileRefList;
use MzML::SpectrumList;
use MzML::ChromatogramList;

with 'MzML::CommonParams';

has 'defaultInstrumentConfigurationRef' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'id' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'sampleRef' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'startTimeStamp' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'spectrumList' => (
    is  => 'rw',
    isa =>  'MzML::SpectrumList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::SpectrumList->new();
        }
    );

has 'chromatogramList' => (
    is  =>  'rw',
    isa =>  'MzML::ChromatogramList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::ChromatogramList->new();
        }
    );

1;
