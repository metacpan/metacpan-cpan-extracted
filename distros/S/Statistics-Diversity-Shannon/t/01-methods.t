#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Statistics::Diversity::Shannon';

my $obj = eval { Statistics::Diversity::Shannon->new };
isa_ok $obj, 'Statistics::Diversity::Shannon';
ok !$@, 'created with no arguments';

dies_ok {
    $obj = Statistics::Diversity::Shannon->new( data => 'foo' )
} 'dies with invalid data';

# https://www.easycalculation.com/statistics/learn-shannon-wiener-diversity.php
lives_ok {
    $obj = Statistics::Diversity::Shannon->new( data => [qw( 60 10 25 1 4 )] )
} 'easycalculation created with valid data';
is $obj->N, 5, 'N';
is $obj->sum, 100, 'sum';
is_deeply $obj->freq, [qw( 0.6 0.1 0.25 0.01 0.04 )], 'freq';
is sprintf( '%.2f', $obj->index ), 1.06, 'index';
is sprintf( '%.2f', $obj->evenness ), 0.66, 'evenness';

# Zooarchaeology pg. 106 https://books.google.com/books?id=aCRaCrdENQ8C
lives_ok {
    $obj = Statistics::Diversity::Shannon->new( freq => [qw( .25 .25 .25 .25 )] )
} 'Zooarchaeology created with valid data';
is $obj->N, 4, 'N';
is $obj->sum, 1, 'sum';
is sprintf( '%.2f', $obj->index ), 1.39, 'index';
is sprintf( '%.2f', $obj->evenness ), '1.00', 'evenness';

lives_ok {
    $obj = Statistics::Diversity::Shannon->new( freq => [qw( .95 .02 .02 .01 )] )
} 'Zooarchaeology 2 created with valid data';
is $obj->N, 4, 'N';
is $obj->sum, 1, 'sum';
is sprintf( '%.2f', $obj->index ), 0.25, 'index';
is sprintf( '%.2f', $obj->evenness ), 0.18, 'evenness';

done_testing();
