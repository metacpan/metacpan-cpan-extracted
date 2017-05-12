#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN { push(@INC, "lib", "t"); }
use TestHelper;

my $mturk = TestHelper->new;

plan tests => 3;
ok( $mturk, "Created client");

my $url = $mturk->getHITTypeURL( "fakeHITTypeID" );
ok($url =~ /fakeHITTypeID/, "GetHITTypeURL contains HITTypeID");
ok($url =~ /mturk\/preview\?/, "GetHITTypeURL looks nice");

# TODO -- should create a real hit, generate the url, then ensure we can access that url
