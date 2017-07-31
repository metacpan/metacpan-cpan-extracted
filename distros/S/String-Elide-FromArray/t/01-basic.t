#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use String::Elide::FromArray qw(elide);

subtest basics => sub {
    is(elide([qw/foo/],               11),
       "foo");
    is(elide([qw/foo bar/],           11),
       "foo, bar");
    is(elide([qw/foo bar baz/],       11),
       "foo, bar,..");
    is(elide([qw/foo bar baz/],       15),
       "foo, bar, baz");
    is(elide([qw/foo bar baz qux/],   15),
       "foo, bar, baz..");
};

subtest "opt:max_items" => sub {
    is(elide([qw/foo bar baz qux/],   15, {max_items => 2}),
       "foo, bar, ..");
};

subtest "opt:list_marker" => sub {
    is(elide([qw/foo bar baz qux/],   15, {max_items => 2, list_marker => 'etc'}),
       "foo, bar, etc");
};

subtest "opt:sep" => sub {
    is(elide([qw/foo bar baz/],       11, {sep => '|'}),
       "foo|bar|baz");
};

subtest "opt:marker" => sub {
    is(elide([qw/foo bar baz/],       11, {marker=>"--"}),
       "foo, bar,--");
};

subtest "opt:max_item_len" => sub {
    is(elide([qw/aaa bbbbb/],         11, {max_item_len=>4}),
       "aaa, bb..");
};

subtest "opt:item_marker" => sub {
    is(elide([qw/aaa bbbbb c d e/],      11, {max_item_len=>4, item_marker=>"*"}),
       "aaa, bbb*..");
};

DONE_TESTING:
done_testing;
