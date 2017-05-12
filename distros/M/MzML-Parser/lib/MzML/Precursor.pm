package MzML::Precursor;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::IsolationWindow;
use MzML::SelectedIonList;
use MzML::Activation;

has 'externalSpectrumID' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'sourceFileRef' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'spectrumRef' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'isolationWindow' => (
    is  =>  'rw',
    isa =>  'MzML::IsolationWindow',
    default => sub {
        my $self = shift;
        return my $obj = MzML::IsolationWindow->new();
        }
    );

has 'selectedIonList' => (
    is  =>  'rw',
    isa =>  'MzML::SelectedIonList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::SelectedIonList->new();
        }
    );

has 'activation' => (
    is  =>  'rw',
    isa =>  'MzML::Activation',
    default => sub {
        my $self = shift;
        return my $obj = MzML::Activation->new();
        }
    );

1;
