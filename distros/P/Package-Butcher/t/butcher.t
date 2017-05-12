#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 'no_plan';
use lib 't/lib';
use Package::Butcher;

my $butcher = Package::Butcher->new(
    {
        package     => 'Dummy',
        do_not_load => [qw/Cannot::Load Cannot::Load2 NoSuch::List::MoreUtils/],
        predeclare  => 'uniq',
        subs => {
            this     => sub { 7 },
            that     => sub { 3 },
            existing => sub { 'replaced existing' },
        },
        method_chains => [
            [
                'Cannot::Load' => qw/foo bar baz this that/ => sub {
                    my $args = join ', ' => @_;
                    return "end chain: $args";
                },
            ],
        ],
    }
);

$butcher->use('existing');
is Dummy::existing(), 'replaced existing', 'FQ subname should be correct';
is existing(), 'replaced existing', 'Exported functions should be correct';
is Dummy::this(), 7, 'A bare value for installing sub should be correct';
is Dummy::that(), 3, 'A subref for installing a sub should be correct';
is Dummy::chain(qw/one two/), 'end chain: one, two',
    'method chains should also work';
