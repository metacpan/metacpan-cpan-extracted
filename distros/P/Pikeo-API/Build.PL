#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

Module::Build->new(
        module_name => 'Pikeo::API',
        license => 'perl',
        requires => {
                'Data::Dumper'              => '0',
                'DateTime::Format::RSS'     => '0',
                'LWP::UserAgent'            => '0',
                'Digest::SHA1'              => '0',
                'Digest::MD5'               => '0',
                'MIME::Base64'              => '0',
                'DateTime::Format::ISO8601' => '0',
                'DateTime'                  => '0',
        },
        build_requires => {
                'Test::More' => '0',
        },
        create_makefile_pl => 'traditional',
        sign => 0,
)->create_build_script;
