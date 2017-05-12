#!/usr/bin/env perl
# eq_hash still works with String::FlexMatch, because deep down it still
# uses the 'eq' operator.
use warnings;
use strict;
use YAML;
use Test::More tests => 4;
use String::FlexMatch::Test;
BEGIN { use_ok('String::FlexMatch') }
my $data = Load do { local $/; <DATA> };
my $hash1 = {
    errors => {
        attr1 => 'A pure string',
        attr2 => '/home/marcel/lib/Foo/Bar.pm',
        attr3 => 58,
        attr4 => 'No such class',
    },
};
ok(eq_hash_flex($data, $hash1), 'Matching hash');
$hash1->{attr5} = 'This should not be here';
ok(!eq_hash_flex($data, $hash1), 'Hash with extra key');
$hash1 = {
    errors => {
        attr1 => 'A pure string',
        attr2 => '/home/marcel/lib/Foo/Bar.pm',
        attr3 => 'abc',
        attr4 => 'No such class',
    },
};
ok(!eq_hash_flex($data, $hash1), 'Hash with word instead of number');
__DATA__
errors:
  attr1: A pure string
  attr2: !perl/String::FlexMatch
    regex: '.*/lib/Foo/Bar.pm'
  attr3: !perl/String::FlexMatch
    regex: '\d+'
  attr4: |-
    No such class
