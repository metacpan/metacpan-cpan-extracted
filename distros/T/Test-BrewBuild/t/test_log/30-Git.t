#!/usr/bin/perl
use strict;
use warnings;

use Capture::Tiny qw(:all);
use Test::BrewBuild::Git;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my ($out) = capture {
    my $g = Test::BrewBuild::Git->new(debug => 7);
    $g->link;

};

like $out, qr/instantiating new object/, "new() has logging";
like $out, qr/git command set/, "git() has logging";
like $out, qr/for the repo/, "link() has logging";

done_testing();
