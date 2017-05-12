#!perl
use Test::More tests => 3;

use strict;
use warnings;

BEGIN { use_ok("Number::Tolerant"); }

# this module can't possibly be loaded:
eval { Number::Tolerant->enable_plugin("..."); };
ok($@, "exception trying to load impossible module");

# this module can be loaded, but isn't a plugin
eval { Number::Tolerant->enable_plugin("Carp"); };
like($@, qr/not a valid .+ plugin/, "Carp isn't a plugin!");
