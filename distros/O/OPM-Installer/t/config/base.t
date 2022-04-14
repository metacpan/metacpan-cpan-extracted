#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;
use File::Basename;
use File::Spec;

use OPM::Installer::Utils::Config;

diag "Testing *::Config version ", OPM::Installer::Utils::Config->VERSION;

my $obj = OPM::Installer::Utils::Config->new(
    conf => File::Spec->catfile( dirname(__FILE__), 'test.rc' ),
);

isa_ok $obj, 'OPM::Installer::Utils::Config';

my $config       = $obj->rc_config;
my $config_check = {
    path  => '/local/app',
    repository => [
        'file://hallo/test',
        'http://opar.perl-services.de/1234',
    ],
};

is_deeply $config, $config_check;

done_testing();
