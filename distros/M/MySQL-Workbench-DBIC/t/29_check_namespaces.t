#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use MySQL::Workbench::DBIC;

my $sub = MySQL::Workbench::DBIC->can('_check_namespace_array');

my @good = (
    [qw/Test V2 Hallo::Test Another::Test::For::Namespaces/],
    [],
    [qw/Test/],
    'Test',
    'Another::Test',
    'V2',
    'Test::2',
);

my @bad = (
    [undef],
    [qw/1/],
    [qw/1 Test/],
    [qw/Hello 1 Test/],
    {},
    (bless {}, 'CGI'),
);

for my $good ( @good ) {
    ok $sub->($good);
}

for my $bad ( @bad ) {
    ok !$sub->($bad);
}

done_testing;
