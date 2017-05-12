#!perl -w


use strict;
use Test::More;

my $tests = 5;
$tests   += 1 if $ENV{NET_SOCIAL_MAPPER_NETWORK_TESTS};
plan tests => $tests;

use_ok("Net::Social::Mapper");
my $mapper;
ok($mapper = Net::Social::Mapper->new, "Got mapper");
my $persona;
ok($persona  = $mapper->persona('sippey', 'typepad'),   "Got persona");
is($persona->user, 'sippey',                            "Got user");
is($persona->homepage, 'http://sippey.typepad.com',     "Got homepage");


exit 0 unless $ENV{NET_SOCIAL_MAPPER_NETWORK_TESTS};
ok(scalar($persona->feeds),                             "Found feeds");

