#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use String::Random::NiceURL qw(id);

# firstly test the passing nothing, zero or one fails
throws_ok { id() } qr/provide a length greater than or equal to/, 'nothing passed caught ok';
throws_ok { id('a') } qr/provide a length greater than or equal to/, 'non-number caught ok';
throws_ok { id(0) } qr/provide a length greater than or equal to/, 'zero caught ok';
throws_ok { id(1) } qr/provide a length greater than or equal to/, 'one caught ok';

for my $l ( 2..11 ) {
    is( length(id($l)), $l, "id of length $l passed" );
}
