use 5.006;
use strict;
use warnings;
use Test::More 0.96;
use File::pushd qw/tempd/;

use lib 't/lib';
use TestHelper;

use Pantry::Model::DataBag;

# creation
subtest "creation" => sub {
  new_ok("Pantry::Model::DataBag", [name => "xdg"]);
};

# create/serialize/deserialize
subtest "freeze/thaw" => sub {
  my $wd=tempd;

  my $bag = Pantry::Model::DataBag->new(name => "web");
  ok( $bag->save_as("bag.json"), "saved a bag" );
  ok( my $thawed = Pantry::Model::DataBag->new_from_file("bag.json"), "thawed bag");
  is( $thawed->name, $bag->name, "thawed name matches original name" );
};

# create with a path
subtest "_path attribute" => sub {
  my $wd=tempd;

  my $bag = Pantry::Model::DataBag->new(
    name => "xdg",
    _path => "bag.json"
  );
  ok( $bag->save, "saved a bag with default path" );
  ok( my $thawed = Pantry::Model::DataBag->new_from_file("bag.json"), "thawed bag");
  is( $thawed->name, $bag->name, "thawed name matches original name" );
};


subtest 'bag attribute CRUD' => sub {
  my $bag = Pantry::Model::DataBag->new(
    name => "xdg",
  );
  $bag->set_attribute("shell" => "/bin/bash");
  is( $bag->get_attribute("shell"), "/bin/bash", "set/got 'shell'" );
  $bag->set_attribute("shell" => "/bin/csh");
  is( $bag->get_attribute("shell"), "/bin/csh", "changed 'shell'" );
  $bag->delete_attribute("shell");
  is( $bag->get_attribute("shell"), undef, "deleted 'shell'" );
};

subtest 'bag attribute serialization' => sub {
  my $wd=tempd;
  my $bag = Pantry::Model::DataBag->new(
    name => "xdg",
    _path => "bag.json",
  );
  $bag->set_attribute("shell" => "/bin/bash");
  $bag->set_attribute("ssh.key" => "DEADBEEF");
  $bag->save;
  my $data = _thaw_file("bag.json");
  is_deeply( $data, {
      id => 'xdg',
      shell => "/bin/bash",
      ssh => {
        key => "DEADBEEF"
      },
    },
    "bag attributes serialized at correct level"
  ) or diag explain $data;
  ok( my $thawed = Pantry::Model::DataBag->new_from_file("bag.json"), "thawed bag");
  my $err;
  is( $thawed->get_attribute("shell"), "/bin/bash", "thawed bag has correct default 'shell'" )
    or $err++;
  is( $thawed->get_attribute("ssh.key"), "DEADBEEF", "thawed bag has correct default 'ssh.key'" )
    or $err++;
  diag "DATA FILE:\n", explain $data if $err;
};

subtest 'bag attribute escape dots' => sub {
  my $wd=tempd;
  my $bag = Pantry::Model::DataBag->new(
    name => "xdg",
    _path => "bag.json",
  );
  $bag->set_attribute('nginx\.port' => 80);
  is( $bag->get_attribute('nginx\.port'), 80, q{set/got 'nginx\.port'} );
  $bag->save;
  my $data = _thaw_file("bag.json");
  is_deeply( $data, {
      id => 'xdg',
      'nginx.port' => 80,
    },
    "bag attributes escaped dot works"
  ) or diag explain $data;
  ok( my $thawed = Pantry::Model::DataBag->new_from_file("bag.json"), "thawed bag");
  is( $thawed->get_attribute('nginx\.port'), 80, q{thawed bag has correct 'nginx\.port'} )
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
