#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin qw($Bin);

use Module::Lazy "Module::Lazy::_::test::sample";

push @INC, "$Bin/lib";

my $foo = bless {}, "Module::Lazy::_::test::sample";
is $Module::Lazy::_::test::sample::loaded, undef, "module not loaded";

lives_ok {
    undef $foo;
} "destroy has no error";

is $Module::Lazy::_::test::sample::loaded, 1, "module loaded after destroy";
is $Module::Lazy::_::test::sample::alive, -1, "1 object destroyed";

# this is more of a self test - check that alive counter actually works
# while module is fully loaded
my $item = Module::Lazy::_::test::sample->new;
is $Module::Lazy::_::test::sample::alive, 0, "1 object created";

undef $item;
is $Module::Lazy::_::test::sample::alive, -1, "1 object destroyed";

done_testing;
