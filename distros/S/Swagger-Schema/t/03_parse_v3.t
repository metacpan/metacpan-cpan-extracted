#!/usr/bin/env perl

use Test::More;
use File::Slurp;
use Swagger::Schema::V3;

{
  # Working with https://github.com/OAI/OpenAPI-Specification/tree/master/examples/v3.0
  # and https://swagger.io/docs/specification/authentication/basic-authentication/
  my $schema = load('t/swagger-examples-v3/petstore.json');
  isa_ok($schema, 'Swagger::Schema::V3');
  isa_ok($schema->security->[0]->{basicAuth}, "ARRAY");
}

sub load {
  my $file = shift;
  my $contents = read_file($file);
  return Swagger::Schema::V3->MooseX::DataModel::new_from_json($contents);
}

done_testing;

