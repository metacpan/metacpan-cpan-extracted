#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin qw($Bin);

use lib "$Bin/lib";
use Module::Lazy "Module::Lazy::_::test::sample";

my $code = Module::Lazy::_::test::sample->can("new");

is ref $code, 'CODE', "can new";
is $Module::Lazy::_::test::sample::VERSION, 42, "module loaded after can";

is( Module::Lazy::_::test::sample->can("can"), UNIVERSAL->can("can")
    , "can() was reset to normal");

done_testing;
