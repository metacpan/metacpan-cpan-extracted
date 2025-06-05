#!/usr/bin/env perl
# -*- mode: cperl; cperl-indent-level: 2 -*-

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);
use Data::Dumper;

use Query::Param;

########################################################################

my $query = 'foo=1&bar=2&foo=3+baz&empty=&encoded=%25%20%2B';

my $args = Query::Param->new($query);

########################################################################
subtest 'basic retrieval' => sub {
########################################################################
  my $val = $args->get('foo');
  is ref $val,          'ARRAY', 'get(foo) returns arrayref for multiple values';
  is $args->get('bar'), '2',     'OO accessor returns bar value';
  ok $args->has('foo'),      'has() confirms foo exists';
  ok !$args->has('missing'), 'has() false for missing key';
};

########################################################################
subtest 'multi-value access' => sub {
########################################################################
  my $val = $args->get('foo');
  is ref $val, 'ARRAY', 'get(foo) returns arrayref for multiple values';
  is_deeply $val, [ '1', '3 baz' ], 'decoded multiple values correct';
};

########################################################################
subtest 'uri decoding' => sub {
########################################################################
  is $args->get('encoded'), '% +', 'handles %25 %20 %2B decoding';
};

########################################################################
subtest 'empty value and missing value' => sub {
########################################################################
  is $args->get('empty'),   q{},   'empty value remains empty string';
  is $args->get('novalue'), undef, 'nonexistent key returns undef';
};

########################################################################
subtest 'set() method' => sub {
########################################################################
  $args->set( 'foo', 'overwritten' );
  $args->set( 'baz', 'newvalue' );

  is $args->get('foo'), 'overwritten', 'set() overwrites foo';
  is $args->get('baz'), 'newvalue',    'set() inserts new key';
};

########################################################################
subtest 'to_string() output' => sub {
########################################################################
  my $out = $args->to_string;

  like $out, qr/\bfoo=overwritten\b/,          'foo is correctly set';
  like $out, qr/\bbaz=newvalue\b/,             'baz appears correctly';
  like $out, qr/\bencoded=%25(?:%20|\+)%2B\b/, 'encoded output preserved with normalized space';
};

########################################################################
subtest 'keys(), values(), pairs() methods' => sub {
########################################################################
  my @keys  = sort $args->keys;
  my @vals  = map { $args->get($_) } @keys;
  my @pairs = $args->pairs;

  ok scalar @keys >= 1,            'keys() returns list of keys';
  ok scalar @vals == scalar @keys, 'values match keys count';
  ok scalar @pairs >= 1,           'pairs() returns key/value pairs';
};

done_testing();

1;
