#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test2::Bundle::More;
use Module::Runtime qw( use_module );

plan(4);

my @modules = qw(
  MXJSTest
  MXJSTestExt
);

for my $module (@modules) {
  eval {
    is(use_module($module), $module, 'Loaded '.$module);
  };
  if ($@) { fail('Loading of module '.$module.' failed with '.$@) }
}

eval {

my $testschema = MXJSTest->meta->json_schema_json( pretty => 1 );

is($testschema,<<'__EOS__', 'Basic class json schema');
{
   "$id" : "https://json-schema.org/perl.mxjstest.schema.json",
   "$schema" : "https://json-schema.org/draft/2020-12/schema",
   "properties" : {
      "age" : {
         "description" : "Current age in years",
         "maximum" : 200,
         "minimum" : 0,
         "type" : "integer"
      },
      "first_name" : {
         "description" : "The first name of the person",
         "type" : "string"
      },
      "last_name" : {
         "description" : "The last name of the person",
         "type" : "string"
      }
   },
   "title" : "A person",
   "type" : "object"
}
__EOS__

};

eval {

my $testextschema = MXJSTestExt->meta->json_schema_json( pretty => 1 );

is($testextschema,<<'__EOS__', 'Extended class json schema');
{
   "$id" : "https://json-schema.org/perl.mxjstestext.schema.json",
   "$schema" : "https://json-schema.org/draft/2020-12/schema",
   "properties" : {
      "age" : {
         "description" : "Current age in years",
         "maximum" : 200,
         "minimum" : 0,
         "type" : "integer"
      },
      "first_name" : {
         "description" : "The first name of the person",
         "type" : "string"
      },
      "job" : {
         "description" : "The job of the person",
         "type" : "string"
      },
      "last_name" : {
         "description" : "The last name of the person",
         "type" : "string"
      }
   },
   "title" : "Extended person",
   "type" : "object"
}
__EOS__

};

done_testing;
