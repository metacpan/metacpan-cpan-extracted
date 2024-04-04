package Stancer::Role::Payment::Auth::Stub;

use 5.020;
use strict;
use warnings;

use Stancer::Core::Types qw(Varchar);

use Moo;
use namespace::clean;

extends 'Stancer::Core::Object';
with 'Stancer::Role::Payment::Auth';

has method => (
    is => 'rw',
    isa => Varchar[10],
);

1;
