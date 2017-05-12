use strict;
use warnings;
use utf8;
use Test::More 0.98;

use Parse::CommandLine;

is_deeply [parse_command_line('var --bar=baz')], ['var', '--bar=baz'];
is_deeply [parse_command_line('var --bar="baz"')], ['var', '--bar=baz'];
is_deeply [parse_command_line('var "--bar=baz"')], ['var', '--bar=baz'];
is_deeply [parse_command_line(q{var "--bar='baz'"})], ['var', q{--bar='baz'}];
is_deeply [parse_command_line(q{var "--bar=\"baz'"})], ['var', q{--bar="baz'}];
is_deeply [parse_command_line(q{var "--bar baz"})], ['var', q{--bar baz}];
is_deeply [parse_command_line(q{var --"bar baz"})], ['var', q{--bar baz}];
is_deeply [parse_command_line(q{var  --"bar baz"})], ['var', q{--bar baz}];

done_testing;
