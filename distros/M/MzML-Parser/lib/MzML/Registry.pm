package MzML::Registry;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::FileDescription;
use MzML::ReferenceableParamGroupList;
use MzML::SampleList;
use MzML::InstrumentConfigurationList;
use MzML::SoftwareList;
use MzML::ScanSettingsList;
use MzML::DataProcessingList;
use MzML::Run;

has 'mzML' => (
    is  =>  'rw',
    isa =>  'MzML::MzML',
    );

has 'cvlist' => (
    is  =>  'rw',
    isa =>  'MzML::CvList',
    );

has 'fileDescription' => (
    is  =>  'rw',
    isa =>  'MzML::FileDescription',
    default => sub {
        my $self = shift;
        return my $obj = MzML::FileDescription->new();
        }
    );

has 'referenceableParamGroupList' => (
    is  =>  'rw',
    isa =>  'MzML::ReferenceableParamGroupList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::ReferenceableParamGroupList->new();
        }
    );

has 'sampleList' => (
    is  =>  'rw',
    isa =>  'MzML::SampleList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::SampleList->new();
        }
    );

has 'instrumentConfigurationList' => (
    is  =>  'rw',
    isa =>  'MzML::InstrumentConfigurationList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::InstrumentConfigurationList->new();
        }
    );

has 'softwareList' => (
    is  =>  'rw',
    isa =>  'MzML::SoftwareList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::SoftwareList->new();
        }
    );

has 'scanSettingsList' => (
    is  =>  'rw',
    isa =>  'MzML::ScanSettingsList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::ScanSettingsList->new();
        }
    );

has 'dataProcessingList' => (
    is  =>  'rw',
    isa =>  'MzML::DataProcessingList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::DataProcessingList->new();
        }
    );

has 'run' => (
    is  =>  'rw',
    isa =>  'MzML::Run',
    default => sub {
        my $self = shift;
        return my $obj = MzML::Run->new();
        }
    );

1;
