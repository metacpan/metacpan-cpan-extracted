#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

Module::Build->new(
	module_name         => 'Sub::Private',
    license             => 'perl',
    # dist_author         => 'Peter Makholm <peter@makholm.net>',
    dist_author         => 'Nigel Horne <njh@bandsman.co.uk>',
    dist_version_from   => 'lib/Sub/Private.pm',
    configure_requires => { 'Module::Build' => 0.42 },
    build_requires => {
        'Test::More' => 0,
        'Test::NoWarnings' => 0,
    },
    requires => {
        'Attribute::Handlers'  => 0,
        'namespace::clean'     => 0,
        'B::Hooks::EndOfScope' => 0,
        'Sub::Identify'        => 0,
    },
    add_to_cleanup      => [ 'Sub-Private-*' ],
    meta_merge => {
        resources => {
		# repository => 'https://github.com/nigelhorne/Sub-Private',
		# RT#154368
		repository => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Private',
		bugtracker => 'https://github.com/nigelhorne/Sub-Private/issues',
        }
    },
    test_requires => {
	'Test::Most' => 0,	# RT#154368
    	'Test::Needs' => 0,
    }
)->create_build_script();
