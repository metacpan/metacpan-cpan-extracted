use 5.006;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep 0.110 qw/cmp_deeply/;
use File::pushd qw/tempd/;
use File::Slurp qw/read_file/;
use Path::Class;
use JSON;
use File::Temp;

use Pantry::Model::Pantry;

my @temps;
sub _new_pantry_ok {
  push @temps, File::Temp->newdir;
  return new_ok("Pantry::Model::Pantry", [path => $temps[-1]]);
}

subtest "constructor" => sub {
  _new_pantry_ok();
};

subtest "list nodes when empty" => sub {
  my $pantry = _new_pantry_ok();
  is( scalar $pantry->all_nodes, 0, "all_nodes gives count of 0 (scalar)" );
  is_deeply( [$pantry->all_nodes], [], "all_nodes gives empty list (list)" );
};

subtest "node are lower case" => sub {
  my $pantry = _new_pantry_ok();
  ok( my $node = $pantry->node("FOO.example.com"), "created a node");
  is( $node->name, lc $node->name, "node name is lc" );
  is( $node->path->basename, lc $node->path->basename, "node basename is lc" );
};

subtest "create/retrieve a node" => sub {
  my $pantry = _new_pantry_ok();
  ok( my $node = $pantry->node("foo.example.com"), "created a node");
  $node->save;
  ok( -e file( $pantry->path =>, 'environments', '_default', 'foo.example.com.json'),
      "saved a node"
  );
  ok( my $node2 = $pantry->node("foo.example.com"), "retrieved a node");
  ok( $node2->save, "saved it again" );
};

subtest "create/retrieve a node in an environement" => sub {
  my $pantry = _new_pantry_ok();
  ok( my $node = $pantry->node("foo.example.com", { env => "test" }), "created a node in test environment");
  $node->save;
  ok( -e file( $pantry->path =>, 'environments', 'test', 'foo.example.com.json'),
      "saved a node to test environment directory"
  );
  ok( my $node2 = $pantry->node("foo.example.com", { env => "test"}), "retrieved a node from test environement");
  is( $node2->env, 'test', "node.chef_environment correct" );
  ok( $node2->save, "saved it again" );
};

subtest "list nodes when some exist" => sub {
  my $pantry = _new_pantry_ok();
  ok( $pantry->node("foo.example.com")->save, "created a node");
  ok( $pantry->node("foo2.example.com")->save, "created another node");
  is( scalar $pantry->all_nodes, 2, "all_nodes gives count of 2 (scalar)" );
  is_deeply( [sort $pantry->all_nodes], [sort qw/foo.example.com foo2.example.com/],
    "all_nodes gives correct list (list)"
  );
};

subtest "list nodes in all environments" => sub {
  my $pantry = _new_pantry_ok();
  ok( $pantry->node("foo.example.com")->save, "created a node");
  ok( $pantry->node("foo2.example.com", {env => 'test'})->save, "created another node in test env");
  is( scalar $pantry->all_nodes, 2, "all_nodes gives count of 2 (scalar)" );
  cmp_deeply( [sort $pantry->all_nodes], [sort qw/foo.example.com foo2.example.com/],
    "all_nodes gives correct list (list)"
  );
};

subtest "list nodes in default environment only" => sub {
  my $pantry = _new_pantry_ok();
  ok( $pantry->node("foo.example.com")->save, "created a node");
  ok( $pantry->node("foo2.example.com", {env => 'test'})->save, "created another node in test env");
  is( scalar $pantry->all_nodes( {env => '_default'} ), 1, "all_nodes gives count of 1 (scalar)" );
  cmp_deeply( [sort $pantry->all_nodes( {env => '_default' } )], [sort qw/foo.example.com/],
    "all_nodes gives correct list (list)"
  );
};

subtest "list nodes in specified environment" => sub {
  my $pantry = _new_pantry_ok();
  ok( $pantry->node("foo.example.com")->save, "created a node");
  ok( $pantry->node("foo2.example.com", {env => 'test'})->save, "created another node in test env");
  is( scalar $pantry->all_nodes( {env => 'test'} ), 1, "all_nodes(\\\%opt) gives count of 1 (scalar)" );
  is_deeply( [sort $pantry->all_nodes( {env => 'test'} )], [sort qw/foo2.example.com/],
    "all_nodes(\\\%opt) gives correct list (list)"
  );
};

subtest "find nodes matching a partial name" => sub {
  my $pantry = _new_pantry_ok();
  for my $name (qw/foo bar baz/) {
    ok( my $node = $pantry->node("$name.example.com"), "created $name");
    $node->save;
  }
  my @found = $pantry->find_node("foo");
  is ( scalar @found, 1, "search on 'foo' found 1 node" );
  is ( $found[0]->name, 'foo.example.com', "found correct node" );
  @found = $pantry->find_node("ba");
  is ( scalar @found, 2, "search on 'ba' found 2 nodes" );
  @found = $pantry->find_node("zzz");
  is ( scalar @found, 0, "search on 'zzz' found 0 nodes" );
};

subtest "find nodes matching a partial name across environment" => sub {
  my $pantry = _new_pantry_ok();
  for my $name (qw/foo bar baz wibbit/) {
    ok( my $node = $pantry->node("$name.example.com"), "created $name");
    $node->save;
  }
  for my $name (qw/wibble wobble/) {
    ok( my $node = $pantry->node("$name.example.com", {env => 'test'}),
      "created $name in test env"
    );
    $node->save;
  }
  my @found = $pantry->find_node("wib");
  is ( scalar @found, 2, "search on 'wib' found 2 nodes" );
  is_deeply( [sort map { $_->name } @found], [sort map { "$_.example.com" } qw/wibbit wibble/],
    "search on 'wib' gives correct list (list)"
  );
  @found = $pantry->find_node("wib", {env => 'test'});
  is ( scalar @found, 1, "search on 'wib' in test env found 1 node" );
  is ( $found[0]->name, 'wibble.example.com', "found correct node" );
};

subtest "find environments when nodes exist" => sub {
  my $pantry = _new_pantry_ok();
  ok( $pantry->node("foo.example.com")->save, "created a node");
  ok( $pantry->environment("test")->save, "created test env" );
  ok( $pantry->node("foo2.example.com", {env => 'test'})->save, "created another node in test env");
  my @envs = $pantry->find_environment("test");
  is ( scalar @envs, 1, "env search on 'test' found 1 env" );
};

done_testing;
#
# This file is part of Pantry
#
# This software is Copyright (c) 2011 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
