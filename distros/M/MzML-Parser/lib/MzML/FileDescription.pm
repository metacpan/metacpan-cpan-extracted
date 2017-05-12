package MzML::FileDescription;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::FileContent;
use MzML::SourceFileList;
use MzML::Contact;

has 'fileContent' => (
    is  =>  'rw',
    isa =>  'MzML::FileContent',
    default => sub {
        my $self = shift;
        return my $obj = MzML::FileContent->new();
        }
    );

has 'sourceFileList' => (
    is  =>  'rw',
    isa =>  'MzML::SourceFileList',
    default => sub {
        my $self = shift;
        return my $obj = MzML::SourceFileList->new();
        }
    );

has 'contact' => (
    is  =>  'rw',
    isa =>  'MzML::Contact',
    );

1;
