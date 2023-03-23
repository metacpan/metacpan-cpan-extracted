#!/usr/bin/perl
#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2014-2023 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Test2::V0;
use Scalar::Util;

my $json_text = q(
{
   "size": "200G",
   "rw": true,
   "ro": false,
   "mountpoints": [
      null
   ],
   "mounts": [
   ],
   "blocks": 250
}
);

my $perl_structure = {
    'blocks' => 250,
	'mountpoints' => [
	    undef
	],
	'mounts' => [],
	'ro' => 0,
	'rw' => 1,
	'size' => '200G'
};

# JSON support from JSON::PP instead of JSON::MaybeXS
# - boolean_values method required
# - module included in basic perl modules
use JSON::PP;
# This load StorageDisplay::Collect::JSON;

my $jsonparser = JSON::PP->new;
my $boolean_support = 0;
eval {
    $jsonparser->boolean_values(0, 1);
    $boolean_support = 1;
};
diag("JSON::PP: boolean_values support: ".$boolean_support);
my $bignum_support = 0;
eval {
    $jsonparser->allow_bignum;
    $bignum_support =1;
};
diag("JSON::PP: allow_bignum support: ".$bignum_support);

use StorageDisplay::Collect;
my $has_boolean_values = StorageDisplay::Collect::JSON::pp_parser_has_boolean_values();
is(defined($has_boolean_values), !1,
    "StorageDisplay::Collect::JSON initialization is delayed");
my $data_structure = StorageDisplay::Collect::JSON::decode_json($json_text);
$has_boolean_values = StorageDisplay::Collect::JSON::pp_parser_has_boolean_values();
is(defined($has_boolean_values), !0,
    "StorageDisplay::Collect::JSON is initialized");
diag("JSON::PP has boolean_values: ".$has_boolean_values);

my $parser = StorageDisplay::Collect::JSON->new();
ok(Scalar::Util::blessed $parser && $parser->isa("JSON::PP"), "StorageDisplay::Collect::JSON inherits JSON::PP");
if ($boolean_support) {
    is($parser->isa("StorageDisplay::Collect::JSON"), !1, "Directly uses JSON::PP::decode");
} else {
    ok($parser->isa("StorageDisplay::Collect::JSON"), "Wrapper around JSON::PP::decode");
}

is(
    $data_structure,
    $perl_structure,
    "decoding JSON data",
    "decoded JSON data were not the expected one",
    );

is(
    $data_structure,
    hash {
	all_values(
	    meta {
		prop blessed => F(),
	    }),
	    etc(),
    },
    "No values are objects",
    "In particular, no JSON::*::Boolean accepted");

use Data::Dumper;

my $perl_str = Dumper($data_structure);

#diag($perl_str);

my $VAR1;
{
    eval $perl_str;
}

is(
    $VAR1,
    $perl_structure,
    "loading Data::Dumper data",
    "loaded Data::Dumper data were not the expected one",
    );

done_testing;   # reached the end safely

