#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN { push(@INC, "lib", "t"); }
use TestHelper;

my $mturk = TestHelper->new;

plan tests => 2;
ok( $mturk, "Created client" );

my $result = $mturk->expectError("AWS.ParameterOutOfRange", sub {
    my $hits = $mturk->SearchHITsAll( PageSize => 101 );
    $hits->next;
});

ok($result, "Expected error in SearchHITsAll");
