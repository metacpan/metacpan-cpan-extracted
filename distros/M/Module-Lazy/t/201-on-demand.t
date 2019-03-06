#!perl

use strict;
use warnings;
use Test::More tests => 5;

use File::Basename qw(dirname);
use lib dirname(__FILE__)."/lib"; # t/lib

require Module::Lazy;

Module::Lazy->import( "Module::Lazy::_::test::sample" );
is $Module::Lazy::_::test::sample::loaded, undef, "not loaded yet";

Module::Lazy->import( "Module::Lazy::_::test::sample" );
is $Module::Lazy::_::test::sample::loaded, undef, "not loaded second time";

my $new = eval {
    Module::Lazy::_::test::sample->new;
};
is $@, '', "no exception on new()";

is ref $new, "Module::Lazy::_::test::sample", "new() worked";
is $Module::Lazy::_::test::sample::loaded, 1, "loaded module at this point";

