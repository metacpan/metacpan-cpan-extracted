#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin qw($Bin);

use lib "$Bin/lib";
use Module::Lazy "Module::Lazy::_::test::subclass";

my $isa = Module::Lazy::_::test::subclass->isa("Module::Lazy::_::test::sample");

ok $isa, "isa correct";
is $Module::Lazy::_::test::subclass::VERSION, 3.14, "subclass loaded";
is $Module::Lazy::_::test::sample::VERSION, 42, "base class loaded";

done_testing;
