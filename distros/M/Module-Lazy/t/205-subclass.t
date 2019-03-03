#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin qw($Bin);

use lib "$Bin/lib";
use Module::Lazy "Module::Lazy::_::test::subclass";

my $item;
lives_ok {
    $item = Module::Lazy::_::test::subclass->new;
} "inherited method acts as expected";

lives_ok {
    is( $item->frobnicate, 42, "subclass actually loaded" );
} "frobnicate lives";
is $Module::Lazy::_::test::sample::alive, 1, "parent new() called";

undef $item;
is $Module::Lazy::_::test::sample::alive, 0, "parent DESTROY() called";

done_testing;
