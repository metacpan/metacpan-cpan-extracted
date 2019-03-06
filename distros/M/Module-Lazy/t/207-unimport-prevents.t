#!perl

use strict;
use warnings;
use Test::More tests => 1;

use FindBin qw($Bin);
use lib "$Bin/lib";

no Module::Lazy;
use Module::Lazy "Module::Lazy::_::test::sample";

is $Module::Lazy::_::test::sample::VERSION, 42, "module loaded unconditionally";

