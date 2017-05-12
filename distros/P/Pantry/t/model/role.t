use 5.006;
use strict;
use warnings;
use Test::More 0.96;
use File::pushd qw/tempd/;

use lib 't/lib';
use TestHelper;

use Pantry::Model::Role;

# creation
subtest "creation" => sub {
  new_ok("Pantry::Model::Role", [name => "web"]);
};

# create/serialize/deserialize
subtest "freeze/thaw" => sub {
  my $wd=tempd;

  my $role = Pantry::Model::Role->new(name => "web");
  ok( $role->save_as("role.json"), "saved a role" );
  ok( my $thawed = Pantry::Model::Role->new_from_file("role.json"), "thawed role");
  is( $thawed->name, $role->name, "thawed name matches original name" );
};

# create with a path
subtest "_path attribute" => sub {
  my $wd=tempd;

  my $role = Pantry::Model::Role->new(
    name => "web",
    _path => "role.json"
  );
  ok( $role->save, "saved a role with default path" );
  ok( my $thawed = Pantry::Model::Role->new_from_file("role.json"), "thawed role");
  is( $thawed->name, $role->name, "thawed name matches original name" );
};

# runlist manipulation
subtest 'append to / remove from runlist' => sub {
  my $role = Pantry::Model::Role->new(
    name => "web",
  );
  $role->append_to_run_list( "foo", "bar" );
  is_deeply([qw/foo bar/], [$role->run_list], "append two items");
  $role->append_to_run_list( "baz" );
  is_deeply([qw/foo bar baz/], [$role->run_list], "append another");
  $role->remove_from_run_list("bar");
  is_deeply([qw/foo baz/], [$role->run_list], "remove from middle");
  $role->remove_from_run_list("wibble");
  is_deeply([qw/foo baz/], [$role->run_list], "remove item that doesn't exist");
};

subtest 'role default attribute CRUD' => sub {
  my $role = Pantry::Model::Role->new(
    name => "web",
  );
  $role->set_default_attribute("nginx.port" => 80);
  is( $role->get_default_attribute("nginx.port"), 80, "set/got 'nginx.port'" );
  $role->set_default_attribute("nginx.port" => 8080);
  is( $role->get_default_attribute("nginx.port"), 8080, "changed 'nginx.port'" );
  $role->delete_default_attribute("nginx.port");
  is( $role->get_default_attribute("nginx.port"), undef, "deleted 'nginx.port'" );
};

subtest 'role override attribute CRUD' => sub {
  my $role = Pantry::Model::Role->new(
    name => "web",
  );
  $role->set_override_attribute("nginx.port" => 80);
  is( $role->get_override_attribute("nginx.port"), 80, "set/got 'nginx.port'" );
  $role->set_override_attribute("nginx.port" => 8080);
  is( $role->get_override_attribute("nginx.port"), 8080, "changed 'nginx.port'" );
  $role->delete_override_attribute("nginx.port");
  is( $role->get_override_attribute("nginx.port"), undef, "deleted 'nginx.port'" );
};

subtest 'role attribute serialization' => sub {
  my $wd=tempd;
  my $role = Pantry::Model::Role->new(
    name => "web",
    _path => "role.json",
  );
  $role->set_default_attribute("nginx.port" => 80);
  $role->set_default_attribute("nginx.user" => "nobody");
  $role->set_override_attribute("set_fqdn" => "web");
  $role->save;
  my $data = _thaw_file("role.json");
  is_deeply( $data, {
      name => 'web',
      json_class => 'Chef::Role',
      chef_type => 'role',
      run_list => [],
      env_run_lists => {},
      default_attributes => {
        nginx => {
          port => 80,
          user => "nobody",
        },
      },
      override_attributes => {
        set_fqdn => "web",
      },
    },
    "role attributes serialized at correct level"
  ) or diag explain $data;
  ok( my $thawed = Pantry::Model::Role->new_from_file("role.json"), "thawed role");
  my $err;
  is( $thawed->get_default_attribute("nginx.port"), 80, "thawed role has correct default 'nginx.port'" )
    or $err++;
  is( $thawed->get_default_attribute("nginx.user"), "nobody", "thawed role has correct default 'nginx.user'" )
    or $err++;
  is( $thawed->get_override_attribute("set_fqdn"), "web", "thawed role has correct override 'set_fqdn'" )
    or $err++;
  diag "DATA FILE:\n", explain $data if $err;
};

subtest 'role attribute escape dots' => sub {
  my $wd=tempd;
  my $role = Pantry::Model::Role->new(
    name => "web",
    _path => "role.json",
  );
  $role->set_default_attribute('nginx\.port' => 80);
  $role->set_override_attribute('deep.attribute.dotted\.name' => 'bar');
  is( $role->get_default_attribute('nginx\.port'), 80, q{set/got 'nginx\.port'} );
  is( $role->get_override_attribute('deep.attribute.dotted\.name'), 'bar', q{set/got 'deep.attribute.dotted\.name'} );
  $role->save;
  my $data = _thaw_file("role.json");
  is_deeply( $data, {
      name => 'web',
      json_class => 'Chef::Role',
      chef_type => 'role',
      run_list => [],
      env_run_lists => {},
      default_attributes => {
        'nginx.port' => 80,
      },
      override_attributes => {
        'deep' => {
          attribute => {
            'dotted.name' => 'bar',
          },
        },
      },
    },
    "role attributes escaped dot works"
  ) or diag explain $data;
  ok( my $thawed = Pantry::Model::Role->new_from_file("role.json"), "thawed role");
  is( $thawed->get_default_attribute('nginx\.port'), 80, q{thawed role has correct 'nginx\.port'} )
    or diag explain $thawed;
  is( $thawed->get_override_attribute('deep.attribute.dotted\.name'), 'bar', q{thawed role has correct 'deep.attribute.dotted\.name'} )
    or diag explain $thawed;
};

subtest 'append to / remove from environment runlist' => sub {
  my $wd=tempd;
  my $role = Pantry::Model::Role->new(
    name => "web",
    _path => "role.json",
  );
  $role->append_to_env_run_list( 'test', ["foo", "bar"] );
  is_deeply([qw/foo bar/], [$role->get_env_run_list('test')->run_list], "append two items to test environment");
  $role->append_to_env_run_list( 'test', ["baz"] );
  is_deeply([qw/foo bar baz/], [$role->get_env_run_list('test')->run_list], "append another");
  $role->remove_from_env_run_list('test', ["bar"]);
  is_deeply([qw/foo baz/], [$role->get_env_run_list('test')->run_list], "remove from middle");
  $role->remove_from_run_list('test', ["wibble"]);
  is_deeply([qw/foo baz/], [$role->get_env_run_list('test')->run_list], "remove item that doesn't exist");
  $role->save;
  my $data = _thaw_file("role.json");
  is_deeply( $data, {
      name => 'web',
      json_class => 'Chef::Role',
      chef_type => 'role',
      run_list => [],
      env_run_lists => {
        test => [qw/foo baz/],
      },
      default_attributes => {},
      override_attributes => {},
    },
    "env_run_lists serialized correctly"
  ) or diag explain $data;
  ok( my $thawed = Pantry::Model::Role->new_from_file("role.json"), "thawed role");
  is_deeply([qw/foo baz/], [$thawed->get_env_run_list('test')->run_list], "env_run_lists round-tripped correctly");
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
