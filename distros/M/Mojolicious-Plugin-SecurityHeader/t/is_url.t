#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Mojolicious::Plugin::SecurityHeader;

my @tests = (
    {
        input  => undef,
        result => undef,
    },
    {
        input  => [],
        result => undef,
    },
    {
        input  => {},
        result => undef,
    },
    {
        input  => '*',
        result => '*',
    },
    {
        input  => 'http://perl-services.de',
        result => 'http://perl-services.de',
    },
    {
        input  => 'ftp://perl-services.de',
        result => undef,
    },
    {
        input  => 'test http://perl-services.de',
        result => undef,
    },
);

my $sub = Mojolicious::Plugin::SecurityHeader->can( '_is_url' );

ok $sub, "Plugin can '_is_url'";

my $cnt = 0;

for my $test ( @tests ) {
    my $check = $test->{result};
    my $input = $test->{input};

    my $result = $sub->( $input );
    is $result, $check, "Test#$cnt";

    $cnt++;
}

done_testing();
