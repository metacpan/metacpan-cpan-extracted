#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;
use File::Basename;
use File::Spec;

use OPM::Installer::Utils::Config;

my $obj = OPM::Installer::Utils::Config->new(
    conf => File::Spec->catfile( dirname(__FILE__), 'test.rc2' ),
);

isa_ok $obj, 'OPM::Installer::Utils::Config';

my $error;
my $config;
eval {
    $config = $obj->rc_config;
    1;
} or $error = $@;

like $error, qr/Config file .* does not exist/;
ok !$config;

done_testing();
