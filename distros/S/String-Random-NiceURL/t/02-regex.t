#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use String::Random::NiceURL qw(id);

for my $l ( 2..11 ) {
    my $id = id($l);
    like( $id, qr/ \A [A-Za-z0-9][A-Za-z0-9-_]*[A-Za-z0-9] \z /xms, "id of length $l passes regex" );
}
