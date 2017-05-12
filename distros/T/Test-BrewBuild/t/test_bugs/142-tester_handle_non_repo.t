#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild::Git;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $git = Test::BrewBuild::Git->new;

my $ok;

$ok = eval {
    $git->clone('http://github.com/stevieb9/blah');
    1;
};

is $ok, undef, "Git::clone() fails if repo can't be cloned (http)";
like $@, qr/can't clone/, "... and error is sane";

undef $@;

$ok = eval {
    $git->clone('https://github.com/stevieb9/blah');
    1;
};

is $ok, undef, "Git::clone() fails if repo can't be cloned (https)";
like $@, qr/can't clone/, "... and error is sane";

done_testing();
