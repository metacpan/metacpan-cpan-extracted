#!perl

use strict;
use warnings;
use Test::More tests => 3;
use Test::Warn;
use Test::Exception;

use Module::Lazy "Module::Lazy::_::test::sample";

use FindBin qw($Bin);
use lib "$Bin/lib";

warnings_are {
    lives_ok {
        require Module::Lazy::_::test::sample;
    } "no exceptions";
} [], "no warnings";

my $item = Module::Lazy::_::test::sample->new;
is ref $item, "Module::Lazy::_::test::sample", "instantiated correctly";

