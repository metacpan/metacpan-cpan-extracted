#!perl -w

use strict;
use Test::More tests => 1;

BEGIN { use_ok 'MouseX::YAML' }

diag "Testing MouseX::YAML/$MouseX::YAML::VERSION";

diag sprintf '   using %s/%s', MouseX::YAML->backend, MouseX::YAML->backend->VERSION;
