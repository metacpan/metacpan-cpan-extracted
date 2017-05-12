#!/usr/bin/perl

use strict;
use Module::Build;

Module::Build->new(
    module_name     => 'Net::IChat',
    license         => 'perl',
    requires        => {
			'perl' => 5.008,
			'Net::Rendezvous' => '0.86',
			'Net::Rendezvous::Publish' => '0.01',
			'LWP::UserAgent' => '2.032',
			'IO::Socket' => 0,
			'XML::LibXML' => '1.58',
			'Class::Accessor::Chained' => '0.01',
			'Sys::Hostname' => '1.11',
		       },
    build_requires => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'traditional',
   )->create_build_script;
