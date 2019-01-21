#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use MySQL::Workbench::DBIC;

my $sub = MySQL::Workbench::DBIC->can('_check_namespace');

my @good = (
    'Test',
    'Another::Test',
    'V2',
    'Test::2',
);

my @bad = (
    [undef],
    undef,
    '2',
    '-test',
    '0',
    '',
    {},
    (bless {}, 'CGI'),
);

for my $good ( @good ) {
    ok $sub->($good);
}

for my $bad ( @bad ) {
    ok !$sub->($bad);
}

ok $sub->('', 1);  # allow empty string

done_testing;
