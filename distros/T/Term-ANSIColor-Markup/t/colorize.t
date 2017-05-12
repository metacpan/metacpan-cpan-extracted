use strict;
use Test::Base;
use Term::ANSIColor::Markup;

plan tests => 1 * blocks;
filters {
    input    => [qw(chomp colorize)],
    expected => [qw(chomp eval)],
};
run_is input => 'expected';

sub colorize { Term::ANSIColor::Markup->colorize(shift) }

__DATA__

=== Basic markup
--- input
aaa<red>bbb</red>ccc
--- expected
"aaa\e[31mbbb\e[0mccc"

=== Nested tags
--- input
aaa<red>bbb<bold>ccc</bold>ddd<blue>eee</blue>fff</red>ggg<black><on_yellow>hhh</on_yellow></black>iii
--- expected
"aaa\e[31mbbb\e[1mccc\e[0m\e[31mddd\e[34meee\e[0m\e[31mfff\e[0mggg\e[30m\e[43mhhh\e[0m\e[30m\e[0miii"

=== Includes not-color tag
--- input
aaa<blue>bbb<foo>ccc<red>ddd</red>eee</foo>fff</blue>ggg
--- expected
"aaa\e[34mbbb<foo>ccc\e[31mddd\e[0m\e[34meee</foo>fff\e[0mggg"

=== Unescape '&lt;' and '&gt;'
--- input
aaa<blue>&lt;bbb<red>ccc</red>ddd</foo>eee</blue>&gt;fff
--- expected
"aaa\e[34m<bbb\e[31mccc\e[0m\e[34mddd</foo>eee\e[0m>fff"
