#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Test::More 'tests' => 10;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../lib";
use String::Splitter;

my $ss;
lives_ok( sub { $ss = String::Splitter->new() }, 'new()' );

dies_ok( sub { $ss->all_splits() }, 'all_splits() missing param' );
dies_ok( sub { $ss->all_splits('') }, 'all_splits("") empty string' );

my $results_expected;
my $results_obtained;

$results_expected = [ ['A'] ];
$results_obtained = $ss->all_splits("A");
is_deeply( $results_expected, $results_obtained, 'all_splits("A")' );

$results_expected = [
    [ 'A',   'B', 'C', 'D' ],
    [ 'AB',  'C', 'D' ],
    [ 'A',   'B', 'CD' ],
    [ 'ABC', 'D' ],
    [ 'A',  'BC', 'D' ],
    [ 'AB', 'CD' ],
    [ 'A',  'BCD' ],
    ['ABCD']
];

$results_obtained = $ss->all_splits("ABCD");
is_deeply( $results_expected, $results_obtained, 'all_splits("ABCD")' );

$results_expected = [ [ "\x{263A}", "\x{263B}" ], ["\x{263A}\x{263B}"] ];
$results_obtained = $ss->all_splits("\x{263A}\x{263B}");
is_deeply( $results_expected, $results_obtained, 'all_splits(utf8)' );

dies_ok( sub { $ss->all_substrings() }, 'all_substrings() missing param' );
dies_ok( sub { $ss->all_substrings('') }, 'all_substrings("") empty string' );

$results_expected = [ 'A', 'ABC', 'BC', 'ABCA', 'B', 'BCA', 'C', 'CA', 'AB' ];

$results_obtained = $ss->all_substrings("ABCA");
is_deeply( $results_expected, $results_obtained, 'all_substrings("ABCA")' );

$results_expected = [ "\x{263A}", "\x{263B}", "\x{263A}\x{263B}" ];
$results_obtained = $ss->all_substrings("\x{263A}\x{263B}");
is_deeply( $results_expected, $results_obtained, 'all_substrings(utf8)' );
