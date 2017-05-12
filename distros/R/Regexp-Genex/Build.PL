#!/usr/bin/perl -w
use strict;
use Module::Build;

Module::Build->new(
	module_name => 'Regexp::Genex',
	license => 'perl',
	requires => {
		'YAPE::Regex' => 3.01, # hmm 
		'String::Escape' => 2002.001,
		#perl => 5.6.0,
	},
	create_makefile_pl => 'traditional',
)->create_build_script;

__END__
