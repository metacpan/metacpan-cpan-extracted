#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test2::Bundle::More;
use Module::Runtime qw( use_module );

use MXJSTatt;

my $schema = MXJSTatt->meta->json_schema_json( pretty => 1 );

is($schema,<<'__EOD__', 'MXJSTatt json schema');
{
   "$id" : "https://json-schema.org/perl.mxjstatt.schema.json",
   "$schema" : "https://json-schema.org/draft/2020-12/schema",
   "properties" : {
      "something" : {
         "description" : "A something",
         "type" : "string"
      }
   },
   "title" : "An attribute",
   "type" : "object"
}
__EOD__

my $something = MXJSTatt->new(
   something => "Some",
);

my $data = $something->json_schema_data_json( pretty => 1 );

is($data,<<'__EOD__', 'MXJSTatt json data');
{
   "something" : "Some"
}
__EOD__

done_testing;
