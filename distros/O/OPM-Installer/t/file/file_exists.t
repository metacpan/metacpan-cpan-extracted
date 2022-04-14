#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;

use File::Basename;
use File::Spec;
use OPM::Installer::Utils::File;
use HTTP::Tiny;
use HTTP::Tiny::FileProtocol;

my $repo = File::Spec->rel2abs(
    File::Spec->catdir( dirname( __FILE__ ), 'repo' ),
);

my $file = OPM::Installer::Utils::File->new(
    repositories      => [],
    package           => $repo . '/TicketOverviewHooked-5.0.6.opm',
    framework_version => '5.0.20',
    rc_config         => {},
);

isa_ok $file, 'OPM::Installer::Utils::File';

my $path = $file->resolve_path;
is $path, "$repo/TicketOverviewHooked-5.0.6.opm";
is -s $path, -s "$repo/TicketOverviewHooked-5.0.6.opm";

done_testing();
