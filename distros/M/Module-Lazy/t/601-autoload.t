#!perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use Module::Lazy "Module::Lazy::_::test::autoload";

use FindBin qw($Bin);
use lib "$Bin/lib";

my $item;
warnings_are {
    $item = Module::Lazy::_::test::autoload->new;
} [], "no warnings";

like $item->foo(42), qr/->foo\(42\)/, "autoload actually works";

done_testing;
