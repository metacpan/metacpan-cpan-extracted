use 5.006;
use strict;
use warnings;
use Test::More 0.96;
use File::pushd qw/tempd/;
use File::Slurp qw/read_file/;
use JSON;

use lib 't/lib';
use TestHelper;

use Pantry::Model::Node;

# creation
subtest "creation" => sub {
  new_ok("Pantry::Model::Node", [name => "foo.example.com"]);
};

# create/serialize/deserialize
subtest "freeze/thaw" => sub {
  my $wd=tempd;

  my $node = Pantry::Model::Node->new(name => "foo.example.com");
  ok( $node->save_as("node.json"), "saved a node" );
  ok( my $thawed = Pantry::Model::Node->new_from_file("node.json"), "thawed node");
  is( $thawed->name, $node->name, "thawed name matches original name" );
};

# create with a path
subtest "_path attribute" => sub {
  my $wd=tempd;

  my $node = Pantry::Model::Node->new(
    name => "foo.example.com",
    _path => "node.json"
  );
  ok( $node->save, "saved a node with default path" );
  ok( my $thawed = Pantry::Model::Node->new_from_file("node.json"), "thawed node");
  is( $thawed->name, $node->name, "thawed name matches original name" );
};

# create with a host/port/user
subtest "custom host/port/user" => sub {
  my $wd=tempd;

  my $node = Pantry::Model::Node->new(
    name => "foo.example.com",
    pantry_host => 'localhost',
    pantry_port => '2222',
    pantry_user => 'vagrant',
  );
  ok( $node->save_as("node.json"), "saved a node with custom host/port/user" );
  ok( my $thawed = Pantry::Model::Node->new_from_file("node.json"), "thawed node");
  is( $node->pantry_host, 'localhost', "custom host set correctly");
  is( $node->pantry_port, '2222', "custom port set correctly");
  is( $node->pantry_user, 'vagrant', "custom user set correctly");
};

# runlist manipulation
subtest 'append to / remove from runlist' => sub {
  my $node = Pantry::Model::Node->new(
    name => "foo.example.com",
  );
  $node->append_to_run_list( "foo", "bar" );
  is_deeply([qw/foo bar/], [$node->run_list], "append two items");
  $node->append_to_run_list( "baz" );
  is_deeply([qw/foo bar baz/], [$node->run_list], "append another");
  $node->remove_from_run_list("bar");
  is_deeply([qw/foo baz/], [$node->run_list], "remove from middle");
  $node->remove_from_run_list("wibble");
  is_deeply([qw/foo baz/], [$node->run_list], "remove item that doesn't exist");
};

subtest 'node attribute CRUD' => sub {
  my $node = Pantry::Model::Node->new(
    name => "foo.example.com",
  );
  $node->set_attribute("nginx.port" => 80);
  is( $node->get_attribute("nginx.port"), 80, "set/got 'nginx.port'" );
  $node->set_attribute("nginx.port" => 8080);
  is( $node->get_attribute("nginx.port"), 8080, "changed 'nginx.port'" );
  $node->delete_attribute("nginx.port");
  is( $node->get_attribute("nginx.port"), undef, "deleted 'nginx.port'" );
};

subtest 'node attribute serialization' => sub {
  my $wd=tempd;
  my $node = Pantry::Model::Node->new(
    name => "foo.example.com",
    _path => "node.json",
  );
  $node->set_attribute("nginx.port" => 80);
  $node->set_attribute("nginx.user" => "nobody");
  $node->set_attribute("set_fqdn" => "foo.example.com");
  is( $node->get_attribute("nginx.port"), 80, "set/got 'nginx.port'" );
  $node->save;
  my $data = _thaw_file("node.json");
  is_deeply( $data, {
      name => 'foo.example.com',
      chef_environment => '_default',
      run_list => [],
      nginx => {
        port => 80,
        user => "nobody",
      },
      set_fqdn => "foo.example.com",
    },
    "node attributes serialized at correct level"
  ) or diag explain $data;
  ok( my $thawed = Pantry::Model::Node->new_from_file("node.json"), "thawed node");
  is( $thawed->get_attribute("nginx.port"), 80, "thawed node has correct 'nginx.port'" );
  is( $thawed->get_attribute("nginx.user"), "nobody", "thawed node has correct 'nginx.user'" );
  is( $thawed->get_attribute("set_fqdn"), "foo.example.com", "thawed node has correct 'set_fqdn'" );
};

subtest 'node attribute escape dots' => sub {
  my $wd=tempd;
  my $node = Pantry::Model::Node->new(
    name => "foo.example.com",
    _path => "node.json",
  );
  $node->set_attribute('nginx\.port' => 80);
  $node->set_attribute('deep.attribute.dotted\.name' => 'bar');
  is( $node->get_attribute('nginx\.port'), 80, q{set/got 'nginx\.port'} );
  is( $node->get_attribute('deep.attribute.dotted\.name'), 'bar', q{set/got 'deep.attribute.dotted\.name'} );
  $node->save;
  my $data = _thaw_file("node.json");
  is_deeply( $data, {
      name => 'foo.example.com',
      chef_environment => '_default',
      run_list => [],
      'nginx.port' => 80,
      'deep' => {
        attribute => {
          'dotted.name' => 'bar',
        },
      },
    },
    "node attributes escaped dot works"
  ) or diag explain $data;
  ok( my $thawed = Pantry::Model::Node->new_from_file("node.json"), "thawed node");
  is( $thawed->get_attribute('nginx\.port'), 80, q{thawed node has correct 'nginx\.port'} )
    or diag explain $thawed;
  is( $thawed->get_attribute('deep.attribute.dotted\.name'), 'bar', q{thawed node has correct 'deep.attribute.dotted\.name'} )
    or diag explain $thawed;
};

subtest 'boolean values' => sub {
  my $wd=tempd;
  my $node = Pantry::Model::Node->new(
    name => "foo.example.com",
    _path => "node.json",
  );
  $node->set_attribute('nginx\.enabled' => JSON::true);
  $node->set_attribute('nginx\.logging' => JSON::false);
  ok( $node->get_attribute('nginx\.enabled'), "nginx.enabled is true");
  isa_ok( $node->get_attribute('nginx\.enabled'), "JSON::Boolean", 'nginx.enabled is JSON::Boolean' );
  ok( ! $node->get_attribute('nginx\.logging'), "nginx.logging is true");
  isa_ok( $node->get_attribute('nginx\.logging'), "JSON::Boolean", 'nginx.logging is JSON::Boolean' );
  $node->save;
  my $data = _thaw_file("node.json");
  is_deeply( $data, {
      name => 'foo.example.com',
      chef_environment => '_default',
      run_list => [],
      'nginx.enabled' => JSON::true,
      'nginx.logging' => JSON::false,
    },
    "boolean objects in freeze and thaw data"
  ) or diag explain $data;
  ok( my $thawed = Pantry::Model::Node->new_from_file("node.json"), "thawed node");
  ok( $thawed->get_attribute('nginx\.enabled'), "thawed nginx.enabled is true");
  isa_ok( $thawed->get_attribute('nginx\.enabled'), "JSON::Boolean", 'thawed nginx.enabled is JSON::Boolean' );
  ok( ! $thawed->get_attribute('nginx\.logging'), "thawed nginx.logging is true");
  isa_ok( $thawed->get_attribute('nginx\.logging'), "JSON::Boolean", 'thawed nginx.logging is JSON::Boolean' );
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
