#!/usr/bin/perl -w

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name  => 'Template::Sandbox',
    license      => 'perl',
    dist_author  => 'Sam Graham <libtemplate-sandbox-perl@illusori.co.uk>',
    build_requires => {
        'Cwd'              => 0,
        'FindBin'          => 0,
        'Module::Build'    => 0.07,
        'Test::More'       => 0,
        'Test::Exception'  => 0,
        },
    requires => {
        'Carp'             => 0,
        'Class::Handle'    => 0,
        'Clone'            => 0,
        'Data::Dumper'     => 0,
        'Digest::MD5'      => 0,
        'File::Spec'       => 0,
        'IO::File'         => 0,
        'Log::Any'         => 0.03,
        'Scalar::Util'     => 0,
        'Storable'         => 1.014,
        },
    recommends => {
        'Cache::CacheFactory' => 1.08,
        'Cache::Cache'        => 1.00,
        },
    sign => 1,
    dynamic_config => 0,
    create_makefile_pl => 'passthrough',
    );
$build->create_build_script;
