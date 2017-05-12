#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use String::Elide::Lines qw(elide);

subtest "opt: marker" => sub {
    is(elide("1\n2\n3\n4\n", 4, {marker=>"--"}), "1\n2\n3\n4\n");
    is(elide("1\n2\n3\n4\n", 3, {marker=>"--"}), "1\n2\n--\n");
};

subtest "opt: truncate=bottom" => sub {
    is(elide("1\n2\n3\n4\n", 3, {truncate=>"bottom"}), "1\n2\n..\n");
    is(elide("1\n2\n3\n4\n", 3, {}                  ), "1\n2\n..\n"); # bottom is the default
    is(elide("1\n2\n3\n4\n", 2, {}                  ), "1\n..\n");
    is(elide("1\n2\n3\n4\n", 1, {}                  ), "..\n");
    is(elide("1\n2\n3\n4\n", 0, {}                  ), "");
};

subtest "opt: truncate=top" => sub {
    is(elide("1\n2\n3\n4\n", 3, {truncate=>"top"}), "..\n3\n4\n");
};

subtest "opt: truncate=middle" => sub {
    is(elide("1\n2\n3\n4\n", 3, {truncate=>"middle"}), "1\n..\n4\n");
};

subtest "opt: truncate=ends" => sub {
    is(elide("1\n2\n3\n4\n", 3, {truncate=>"ends"}), "..\n2\n..\n");
};

subtest "markup" => sub {
    my $text = "1\n2\n3\n<elspan prio=0>|\n</elspan>4\n5\n6\n";
    is(elide($text, 7), "1\n2\n3\n|\n4\n5\n6\n");
    is(elide($text, 6), "1\n..\n|\n4\n5\n6\n");
    is(elide($text, 5), "1\n..\n|\n4\n..\n");
    is(elide($text, 4), "..\n|\n4\n..\n");
    is(elide($text, 3), "..\n|\n..\n");
    is(elide($text, 2), "|\n..\n");
    is(elide($text, 1), "|\n");
    is(elide($text, 0), "");

    is(elide("1\n2\n3\n4\n5\n<elspan prio=1>|\n</elspan>6\n7\n8\n9\n10\n", 5), "1\n..\n6\n7\n..\n");
};

subtest "opt: default_prio" => sub {
    is(elide("1\n2\n<elspan prio=1>|\n</elspan>3\n4\n", 3), "..\n3\n4\n");
    is(elide("1\n2\n<elspan prio=1>|\n</elspan>3\n4\n", 3, {default_prio=>2}), "..\n|\n..\n");
};

DONE_TESTING:
done_testing();
