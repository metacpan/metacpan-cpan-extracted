#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME=>'Data::Sofu',
	VERSION_FROM=>'lib/Data/Sofu.pm',
	PREREQ_PM=>{
		Encode=>2.2,
		'Data::Dumper'=>0,
		Carp=>0
	}
);
