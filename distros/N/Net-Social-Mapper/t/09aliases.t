#!perl -w

use strict;
use Test::More;

my $tests = 12;
plan tests => $tests;


my $mapper;
my $persona;
use_ok("Net::Social::Mapper");
ok($mapper = Net::Social::Mapper->new(),                           "Got mapper");

ok($persona  = $mapper->persona("markpasc", "43things"),           "Got persona");
is($persona->user,     "markpasc",                                 "Got user");
is($persona->service,  "43things",                                 "Got service");
is($persona->homepage, "http://www.43things.com/person/markpasc/", "Got homepage");    
is(scalar($persona->feeds), 1,                                     "Got correct number of feeds");

ok($persona  = $mapper->persona("markpasc", "fortythreethings"),   "Got persona through alias");
is($persona->user,     "markpasc",                                 "Got user");
is($persona->service,  "43things",                                 "Got service");
is($persona->homepage, "http://www.43things.com/person/markpasc/", "Got homepage");    
is(scalar($persona->feeds), 1,                                     "Got correct number of feeds");

