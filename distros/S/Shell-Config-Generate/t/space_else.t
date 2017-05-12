use strict;
use warnings;
use 5.008001;
use Shell::Config::Generate qw( win32_space_be_gone );
use Test::More;

plan skip_all => 'test only for NOT cygwin and MSWin32' if $^O =~ /^(cygwin|MSWin32|msys)$/;

plan tests => 2;

ok(Shell::Config::Generate->can('win32_space_be_gone'), 'has win32_space_be_gone function');

is_deeply [win32_space_be_gone 'foo', 'bar', 'baz'], ['foo', 'bar', 'baz'], "returns what is given";
