package MzML::Product;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;
use MzML::IsolationWindow;

has 'isolationWindow' => (
    is  =>  'rw',
    isa =>  'MzML::IsolationWindow',
    default => sub {
        my $self = shift;
        return my $obj = MzML::IsolationWindow->new();
        }
    );

1;
