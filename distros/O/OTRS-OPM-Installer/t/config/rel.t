#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;
use File::Basename;
use File::Spec;

use OTRS::OPM::Installer::Utils::Config;

my $obj = OTRS::OPM::Installer::Utils::Config->new(
    conf => File::Spec->catfile( dirname(__FILE__), 'rel.rc' ),
);

isa_ok $obj, 'OTRS::OPM::Installer::Utils::Config';

my $dir      = dirname __FILE__;
my $otrs_dir = File::Spec->rel2abs( File::Spec->catdir( $dir, 'otrs' ) );

my $config       = $obj->rc_config;
my $config_check = {
    otrs_path  => $otrs_dir,
    repository => [
        'file://hallo/test',
        'http://opar.perl-services.de/1234',
    ],
};

is_deeply $config, $config_check;

done_testing();
