#!/usr/bin/perl

use strict;

package Build_PL;

use Module::Build ();

Module::Build
	-> new(
		module_name 		=> 'Salvation::MacroProcessor',
		dist_abstract 		=> 'Macros definition and processing engine',
		dist_author 		=> [ 'Gennadiy Filatov <kain.winterheart@gmail.com>' ],
		recursive_test_files 	=> 1,
		license 		=> 'perl',
		configure_requires	=> {
			'Module::Build' => 0.36
		},
		requires 		=> {
			'perl'		=> '>= 5.10.1',
'List::MoreUtils' => '0.33',
'Moose' => '2.0402',
'Package::Stash::XS' => '0.25',
'Data::OptList' => '0.107',
'Try::Tiny' => '0.11',
'Sub::Install' => '0.925',
'Class::Load' => '0.13',
'B::Hooks::EndOfScope' => '0.11',
'Sub::Exporter' => '0.982',
'Package::DeprecationManager' => '0.11',
'Class::Load::XS' => '0.03',
'MRO::Compat' => '0.11',
'Carp::Assert' => '0.20',
'namespace::clean' => '0.23',
'Sub::Name' => '0.05',
'Params::Util' => '1.04',
'Package::Stash' => '0.33',
'namespace::autoclean' => '0.13',
'version' => '0.88',
'Eval::Closure' => '0.08',
'Module::Runtime' => '0.013',
'Devel::GlobalDestruction' => '0.04',
'Variable::Magic' => '0.48',
'MooseX::StrictConstructor' => '0.19',

		},
		meta_merge              => {
			resources       => {
				repository => 'https://github.com/kainwinterheart/salvation-macroprocessor.git',
				bugtracker => 'https://github.com/kainwinterheart/salvation-macroprocessor/issues'
			}
		}
	)
	-> create_build_script()
;

exit 0;

