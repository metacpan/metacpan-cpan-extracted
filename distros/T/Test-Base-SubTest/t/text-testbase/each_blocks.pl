#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Text::TestBase::SubTest;
use Test::More;

my $hunk = <<"...";
### bar
    ### baz
        === fugafuga
        --- input
        xxx
        --- expected
        yyy

        === hogehoge
        --- input
        xxx
        --- expected
        yyy

    ### foobar
        === fugafuga
        --- input
        xxx
        --- expected
        yyy

        === hogehoge
        --- input
        xxx
        --- expected
        yyy
...

my $root = Text::TestBase::SubTest->new->parse($hunk);
$root->each_blocks(sub {
    my $block = shift;
    ok $block->name, $block->name;
});

done_testing;
