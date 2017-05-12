#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'POE::Component::ResourcePool::Resource::TokenBucket',
	VERSION_FROM => 'lib/POE/Component/ResourcePool/Resource/TokenBucket.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'Algorithm::TokenBucket' => '0.32', # until method
		'POE::Component::ResourcePool' => 0,
		'MooseX::POE' => '0.08'
	},
);

