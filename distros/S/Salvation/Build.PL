#!/usr/bin/perl

use strict;

package Build_PL;

use Module::Build ();

Module::Build
	-> new(
		module_name 		=> 'Salvation',
		dist_abstract 		=> 'Simple and free architectural solution for huge applications',
		dist_author 		=> [ 'Gennadiy Filatov <kain.winterheart@gmail.com>' ],
		license 		=> 'perl',
		recursive_test_files 	=> 1,
		configure_requires	=> {
			'Module::Build' => 0.36
		},
		requires 		=> {
			'perl'		=> '>= 5.10.1',
			'Carp' 		=> 1.25,
			'Carp::Assert' 	=> 0.20,
			'Digest::MD5' 	=> 2.39,
			'File::Path' 	=> 2.07_03,
			'File::Spec' 	=> 3.3,
			'Getopt::Std' 	=> 1.06,
			'IO::String' 	=> 1.08,
			'Moose' 	=> 2.0402,
			'Scalar::Util' 	=> 1.21,
			'XML::Writer' 	=> 0.615,
			'Module::Load'	=> 0.16,
		},
		meta_merge              => {
			resources       => {
				repository => 'https://github.com/kainwinterheart/Salvation-Framework.git',
				bugtracker => 'https://github.com/kainwinterheart/Salvation-Framework/issues'
			}
		}
	)
	-> create_build_script()
;

exit 0;

