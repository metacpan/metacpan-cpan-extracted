#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'POE::Component::ResourcePool',
	VERSION_FROM => 'lib/POE/Component/ResourcePool.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'POE' => 0,
		'Carp::Clan' => 0,
		'Moose' => '0.37', # undef init_arg, initializer
		'MooseX::POE' => '0.205', # session leaks, aliased role
		'Set::Object' => '1.20', # weak sets
		'Tie::RefHash' => 0,
		'Tie::RefHash::Weak' => '0.08',
		#'MooseX::Types::Set::Object' => 0, # constraints disabled because they are not user params
	},
);

