#!perl

use strict;
use Test::More;
plan(tests=>5);

use_ok("SemanticWeb::OAI::ORE::Agent");

{
  my $agent=SemanticWeb::OAI::ORE::Agent->new;
  is( $agent->name, undef, "new1: name is undef");
  $agent->name("A Person");
  is( $agent->name, "A Person", "new1: name set");
}

{
  my $agent=SemanticWeb::OAI::ORE::Agent->new(uri=>'_:a1');
  is( $agent->uri, '_:a1', 'new2: set uri');
  is( $agent->real_uri, undef, 'new2: bnode gives undef from real_url');
}
