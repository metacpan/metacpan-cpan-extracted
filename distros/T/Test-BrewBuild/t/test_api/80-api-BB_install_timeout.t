#!/usr/bin/perl
use strict;
use warnings;

use Capture::Tiny qw(capture_merged);
use Test::BrewBuild;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

{ #install

    my $stdout = capture_merged {
        my $bb = Test::BrewBuild->new(notest => 1);
        $bb->instance_install(['5.20.3'], 1);
    };

    like ($stdout, qr/failed to install/, "install timeout works");
}

done_testing();

