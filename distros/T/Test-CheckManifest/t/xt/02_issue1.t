#!/usr/bin/perl

use strict;
use warnings;

use Test::CheckManifest;
use Cwd;

{
    my $dir = Cwd::getcwd();
    ok_manifest({ filter => [ qr/\.(git|build)/, qr/Test-CheckManifest-/ ], dir => $dir });

}
