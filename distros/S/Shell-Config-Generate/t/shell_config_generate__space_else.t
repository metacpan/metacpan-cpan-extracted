use Test2::V0 -no_srand => 1;
use Shell::Config::Generate qw( win32_space_be_gone );

skip_all 'test only for NOT cygwin and MSWin32' if $^O =~ /^(cygwin|MSWin32|msys)$/;

ok(Shell::Config::Generate->can('win32_space_be_gone'), 'has win32_space_be_gone function');

is [win32_space_be_gone 'foo', 'bar', 'baz'], ['foo', 'bar', 'baz'], "returns what is given";

done_testing;
