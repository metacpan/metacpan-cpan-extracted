#!perl

use strict;
use warnings;
use Test::More tests => 3;
use Test::Warn;
use Test::Exception;

use Module::Lazy "Module::Lazy::_::test::nodestroy";

use FindBin qw($Bin);
use lib "$Bin/lib";

# Some sick bastard used direct bless instead of new()
#    like normal people do
my $item = bless {}, "Module::Lazy::_::test::nodestroy";

warnings_are {
    lives_ok {
        undef $item;
    } "no exceptions"
} [], "no warnings";

is $Module::Lazy::_::test::nodestroy::VERSION, 42, "module loaded";

