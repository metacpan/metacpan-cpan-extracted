#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;
use File::Basename;
use File::Spec;

use OPM::Installer::Utils::Config;

my $config_check = {
    path  => '/tmp/app',
    repository => [
        'hallo:://hallo/test',
        'http://opar.perl-services.de/1234',
    ],
};

my $obj = OPM::Installer::Utils::Config->new(
    rc_config => $config_check,
);

isa_ok $obj, 'OPM::Installer::Utils::Config';

my $config = $obj->rc_config;
is_deeply $config, $config_check;

done_testing();
