#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

Module::Build->new(
	module_name => 'Object::Meta::Plugin',
	license => 'perl',
	requires => {
		'perl'				=> '5.8.0',
		'Tie::RefHash'		=> '>= 1.3',
	},
	recommends => {
		'Devel::Symdump'	=> '>= 2.0'
	},
	create_makefile_pl => "traditional",
	sign => 1,
)->create_build_script;
