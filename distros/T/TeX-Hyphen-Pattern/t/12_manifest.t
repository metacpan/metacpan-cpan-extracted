#!/usr/bin/env perl -w    # -*- cperl -*-
use strict;
use warnings;
use 5.014000;
use utf8;

use Test::More;

our $VERSION = 0.103;

eval {
    require Test::CheckManifest;
    1;
} or do {
    my $msg = q{Test::CheckManifest 1.01 required to check spelling of POD};
    plan 'skip_all' => $msg;
};

Test::CheckManifest::ok_manifest(
    { 'filter' => [qr/(Debian_CPANTS.txt|[.](svn|bak))/sxm] } );
