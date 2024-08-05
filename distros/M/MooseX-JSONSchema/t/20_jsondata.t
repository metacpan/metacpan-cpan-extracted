#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test2::Bundle::More;
use Module::Runtime qw( use_module );

use MXJSTest;
use MXJSTestExt;

my $person = MXJSTest->new(
   first_name => "Some",
   last_name => "One",
   age => 30,
);

my $persondata = $person->json_schema_data_json( pretty => 1 );

is($persondata,<<'__EOD__', 'Person json data');
{
   "age" : 30,
   "first_name" : "Some",
   "last_name" : "One"
}
__EOD__

my $character = MXJSTestExt->new(
   first_name => "Peter",
   last_name => "Parker",
   job => "Superhero",
   age => 18,
);

my $characterdata = $character->json_schema_data_json( pretty => 1 );

is($characterdata,<<'__EOD__', 'Character json data');
{
   "age" : 18,
   "first_name" : "Peter",
   "job" : "Superhero",
   "last_name" : "Parker"
}
__EOD__

done_testing;
