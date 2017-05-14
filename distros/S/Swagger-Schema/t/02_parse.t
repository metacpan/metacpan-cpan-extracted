#!/usr/bin/env perl

use Test::More;
use File::Slurp;
use Swagger::Schema;

{
  my $schema = load('t/swagger-examples/petstore.json');
  isa_ok($schema, 'Swagger::Schema');
}

{
  my $schema = load('t/swagger-examples/petstore-simple.json');
  isa_ok($schema, 'Swagger::Schema');
}

sub load {
  my $file = shift;
  my $contents = read_file($file);
  return Swagger::Schema->MooseX::DataModel::new_from_json($contents);
}

done_testing;
