package MzML::FileContent;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::ReferenceableParamGroupRef;
use MzML::CvParam;
use MzML::UserParam;

has 'referenceableParamGroupRef' => (
    is  =>  'rw',
    isa =>  'MzML::ReferenceableParamGroupRef',
    default => sub {
        my $self = shift;
        return my $obj = MzML::ReferenceableParamGroupRef->new();
        }
    );

has 'cvParam' => (
    is  =>  'rw',
    isa =>  'MzML::CvParam',
    default => sub {
        my $self = shift;
        return my $obj = MzML::CvParam->new();
        }
    );

has 'userParam' => (
    is  =>  'rw',
    isa =>  'MzML::UserParam',
    default => sub {
        my $self = shift;
        return my $obj = MzML::UserParam->new();
        }
    );

1;
