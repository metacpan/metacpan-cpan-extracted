#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'SSH::Command',
    license     => 'perl',
    dist_author => 'NRG <pavel.odintsov@googlemail.com>',
    requires    => {
        'Data::Dumper'    => 0,
        'Carp'               => '0',
        'Data::Dumper'       => '0',
        'Getopt::Long'       => '0',
        'Test::More'         => '0',
        'Test::LongString'   => '0',
        'Net::SSH2'          => '0',
        'Scope::Guard'       => '0',
        'File::Temp'         => '0',
        'Exporter::Lite'     => '0',
    },
    build_requires => {
        'Test::More'       => '0',
        'Test::LongString' => '0',
        'Exporter::Lite'   => '0',
    },
    create_makefile_pl => 'traditional',
);

$build->create_build_script;

