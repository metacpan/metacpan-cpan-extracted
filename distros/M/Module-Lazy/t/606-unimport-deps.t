#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;

use File::Basename qw(dirname);
use lib dirname(__FILE__)."/lib"; # t/lib

# Load dependency
use Module::Lazy "Module::Lazy::_::test::sample";

# Also load class that lazyloads dependency
use Module::Lazy "Module::Lazy::_::test::depends";

warnings_are {
    lives_ok {
        Module::Lazy->unimport;
    } "no exception";
} [], "no warnings";

done_testing;
