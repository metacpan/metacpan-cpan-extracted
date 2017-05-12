use 5.006;
use strict;
use warnings;
use Test::More 0.96;
use File::pushd qw/tempd/;

use lib 't/lib';
use TestHelper;

use Pantry::Model::Environment;

# creation
subtest "creation" => sub {
  new_ok("Pantry::Model::Environment", [name => "staging"]);
};

# create/serialize/deserialize
subtest "freeze/thaw" => sub {
  my $wd=tempd;

  my $environment = Pantry::Model::Environment->new(name => "staging");
  ok( $environment->save_as("environment.json"), "saved an environment" );
  ok( my $thawed = Pantry::Model::Environment->new_from_file("environment.json"), "thawed environment");
  is( $thawed->name, $environment->name, "thawed name matches original name" );
};

# create with a path
subtest "_path attribute" => sub {
  my $wd=tempd;

  my $environment = Pantry::Model::Environment->new(
    name => "staging",
    _path => "environment.json"
  );
  ok( $environment->save, "saved an environment with default path" );
  ok( my $thawed = Pantry::Model::Environment->new_from_file("environment.json"), "thawed environment");
  is( $thawed->name, $environment->name, "thawed name matches original name" );
};

subtest 'environment default attribute CRUD' => sub {
  my $environment = Pantry::Model::Environment->new(
    name => "staging",
  );
  $environment->set_default_attribute("nginx.port" => 80);
  is( $environment->get_default_attribute("nginx.port"), 80, "set/got 'nginx.port'" );
  $environment->set_default_attribute("nginx.port" => 8080);
  is( $environment->get_default_attribute("nginx.port"), 8080, "changed 'nginx.port'" );
  $environment->delete_default_attribute("nginx.port");
  is( $environment->get_default_attribute("nginx.port"), undef, "deleted 'nginx.port'" );
};

subtest 'environment override attribute CRUD' => sub {
  my $environment = Pantry::Model::Environment->new(
    name => "staging",
  );
  $environment->set_override_attribute("nginx.port" => 80);
  is( $environment->get_override_attribute("nginx.port"), 80, "set/got 'nginx.port'" );
  $environment->set_override_attribute("nginx.port" => 8080);
  is( $environment->get_override_attribute("nginx.port"), 8080, "changed 'nginx.port'" );
  $environment->delete_override_attribute("nginx.port");
  is( $environment->get_override_attribute("nginx.port"), undef, "deleted 'nginx.port'" );
};

subtest 'environment attribute serialization' => sub {
  my $wd=tempd;
  my $environment = Pantry::Model::Environment->new(
    name => "staging",
    _path => "environment.json",
  );
  $environment->set_default_attribute("nginx.port" => 80);
  $environment->set_default_attribute("nginx.user" => "nobody");
  $environment->set_override_attribute("set_fqdn" => "staging");
  $environment->save;
  my $data = _thaw_file("environment.json");
  is_deeply( $data, {
      name => 'staging',
      json_class => 'Chef::Environment',
      chef_type => 'environment',
      default_attributes => {
        nginx => {
          port => 80,
          user => "nobody",
        },
      },
      override_attributes => {
        set_fqdn => "staging",
      },
    },
    "environment attributes serialized at correct level"
  ) or diag explain $data;
  ok( my $thawed = Pantry::Model::Environment->new_from_file("environment.json"), "thawed environment");
  my $err;
  is( $thawed->get_default_attribute("nginx.port"), 80, "thawed environment has correct default 'nginx.port'" )
    or $err++;
  is( $thawed->get_default_attribute("nginx.user"), "nobody", "thawed environment has correct default 'nginx.user'" )
    or $err++;
  is( $thawed->get_override_attribute("set_fqdn"), "staging", "thawed environment has correct override 'set_fqdn'" )
    or $err++;
  diag "DATA FILE:\n", explain $data if $err;
};

subtest 'environment attribute escape dots' => sub {
  my $wd=tempd;
  my $environment = Pantry::Model::Environment->new(
    name => "staging",
    _path => "environment.json",
  );
  $environment->set_default_attribute('nginx\.port' => 80);
  $environment->set_override_attribute('deep.attribute.dotted\.name' => 'bar');
  is( $environment->get_default_attribute('nginx\.port'), 80, q{set/got 'nginx\.port'} );
  is( $environment->get_override_attribute('deep.attribute.dotted\.name'), 'bar', q{set/got 'deep.attribute.dotted\.name'} );
  $environment->save;
  my $data = _thaw_file("environment.json");
  is_deeply( $data, {
      name => 'staging',
      json_class => 'Chef::Environment',
      chef_type => 'environment',
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
    "environment attributes escaped dot works"
  ) or diag explain $data;
  ok( my $thawed = Pantry::Model::Environment->new_from_file("environment.json"), "thawed environment");
  is( $thawed->get_default_attribute('nginx\.port'), 80, q{thawed environment has correct 'nginx\.port'} )
    or diag explain $thawed;
  is( $thawed->get_override_attribute('deep.attribute.dotted\.name'), 'bar', q{thawed environment has correct 'deep.attribute.dotted\.name'} )
    or diag explain $thawed;
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
