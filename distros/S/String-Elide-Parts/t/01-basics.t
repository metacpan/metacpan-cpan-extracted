#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use String::Elide::Parts qw(elide);

subtest "opt: marker" => sub {
    is(elide("1234567890", 5, {marker=>"--"}), "123--");
    is(elide("1234567890", 5, {marker=>"---"}), "12---");
};

subtest "opt: truncate=right" => sub {
    is(elide("1234567890", 11, {truncate=>"right"}), "1234567890");
    is(elide("1234567890", 10, {truncate=>"right"}), "1234567890");
    is(elide("1234567890",  9, {truncate=>"right"}), "1234567..");
    is(elide("1234567890",  9, {}                 ), "1234567.."); # right is the default
    is(elide("1234567890",  5, {truncate=>"right"}), "123..");
    is(elide("1234567890",  3, {truncate=>"right"}), "1..");
    is(elide("1234567890",  2, {truncate=>"right"}), "..");
    is(elide("1234567890",  1, {truncate=>"right"}), ".");
    is(elide("1234567890",  0, {truncate=>"right"}), "");
};

subtest "opt: truncate=left" => sub {
    is(elide("1234567890", 11, {truncate=>"left"}), "1234567890");
    is(elide("1234567890", 10, {truncate=>"left"}), "1234567890");
    is(elide("1234567890",  9, {truncate=>"left"}), "..4567890");
    is(elide("1234567890",  5, {truncate=>"left"}), "..890");
    is(elide("1234567890",  3, {truncate=>"left"}), "..0");
    is(elide("1234567890",  2, {truncate=>"left"}), "..");
    is(elide("1234567890",  1, {truncate=>"left"}), ".");
    is(elide("1234567890",  0, {truncate=>"left"}), "");
};

subtest "opt: truncate=middle" => sub {
    is(elide("1234567890", 11, {truncate=>"middle"}), "1234567890");
    is(elide("1234567890", 10, {truncate=>"middle"}), "1234567890");
    is(elide("1234567890",  9, {truncate=>"middle"}), "123..7890");
    is(elide("1234567890",  8, {truncate=>"middle"}), "123..890");
    is(elide("1234567890",  7, {truncate=>"middle"}), "12..890");
    is(elide("1234567890",  6, {truncate=>"middle"}), "12..90");
    is(elide("1234567890",  5, {truncate=>"middle"}), "1..90");
    is(elide("1234567890",  4, {truncate=>"middle"}), "1..0");
    is(elide("1234567890",  3, {truncate=>"middle"}), "..0");
    is(elide("1234567890",  2, {truncate=>"middle"}), "..");
    is(elide("1234567890",  1, {truncate=>"middle"}), ".");
    is(elide("1234567890",  0, {truncate=>"middle"}), "");
};

subtest "opt: truncate=ends" => sub {
    is(elide("1234567890", 11, {truncate=>"ends"}), "1234567890");
    is(elide("1234567890", 10, {truncate=>"ends"}), "1234567890");
    is(elide("1234567890",  9, {truncate=>"ends"}), "..34567..");
    is(elide("1234567890",  8, {truncate=>"ends"}), "..4567..");
    is(elide("1234567890",  7, {truncate=>"ends"}), "..456..");
    is(elide("1234567890",  6, {truncate=>"ends"}), "..56..");
    is(elide("1234567890",  5, {truncate=>"ends"}), "..5..");
    is(elide("1234567890",  4, {truncate=>"ends"}), "....");
    is(elide("1234567890",  3, {truncate=>"ends"}), "...");
    is(elide("1234567890",  2, {truncate=>"ends"}), "..");
    is(elide("1234567890",  1, {truncate=>"ends"}), ".");
    is(elide("1234567890",  0, {truncate=>"ends"}), "");
};

subtest "markup" => sub {
    my $text = "<elspan prio=2>Downloading</elspan> <elspan prio=3 truncate=middle marker=\"**\">http://www.example.com/somefile</elspan> 320.0k/5.5M";
    is(elide($text, 56), "Downloading http://www.example.com/somefile 320.0k/5.5M");
    is(elide($text, 55), "Downloading http://www.example.com/somefile 320.0k/5.5M");
    is(elide($text, 50), "Downloading http://www.e**com/somefile 320.0k/5.5M");
    is(elide($text, 45), "Downloading http://ww**m/somefile 320.0k/5.5M");
    is(elide($text, 40), "Downloading http://**omefile 320.0k/5.5M");
    is(elide($text, 35), "Downloading http**efile 320.0k/5.5M");
    is(elide($text, 30), "Downloading ht**le 320.0k/5.5M");
    is(elide($text, 25), "Downloading * 320.0k/5.5M");
    is(elide($text, 24), "Downloading  320.0k/5.5M");
    is(elide($text, 23), "Download..  320.0k/5.5M");
    is(elide($text, 20), "Downl..  320.0k/5.5M");
    is(elide($text, 15), "..  320.0k/5.5M");
    is(elide($text, 13), "  320.0k/5.5M");
    is(elide($text, 10), " 320.0k/..");
    is(elide($text,  5), " 32..");
};

subtest "opt:default_prio" => sub {
    my $text = "aaaaa<elspan prio=1>|</elspan>bbbbb";
    is(elide($text, 6), "..bb.."); # shouldn't it be 6 chars and not 5?
    is(elide($text, 5, {default_prio=>2}), "..|..");
};

DONE_TESTING:
done_testing();
