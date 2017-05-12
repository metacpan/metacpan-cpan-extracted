# -*- perl -*-

use strict;
use warnings FATAL => 'all';

# t/003_test.t - test each object method

use Test::More;

BEGIN { use_ok('String::Urandom') }

ok 1;

my $obj = String::Urandom->new(
    LENGTH => 255,
    CHARS  => [ qw( a b c 1 2 3 ) ]
  );

ok( $obj, 'testing new() method' );

my $length = $obj->str_length;
my $chars  = $obj->str_chars;
my $string = $obj->rand_string;

ok 1;

is(
    $length,
    255,
    'testing str_length() method'
  );

is(
    @{$chars}[2],
    'c',
    'testing str_chars() method'
  );

ok(
    $string,
    'testing rand_string() method'
  );

is(
    length($string),
    '255',
    'testing rand_string() length'
  );

like(
    $string,
    qr/[abc123]/,
    'testing rand_string() result'
  );

done_testing();
