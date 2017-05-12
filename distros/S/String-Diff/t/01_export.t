use Test::Base;
use String::Diff qw( diff_fully diff diff_merge diff_regexp );

plan tests => 4;

ok(defined &diff_fully);
ok(defined &diff);
ok(defined &diff_merge);
ok(defined &diff_regexp);
