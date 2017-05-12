use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
	NAME          => 'MooseX::Role::Defaultable',
	AUTHOR        => q{Aaron Cohen <aarondcohen@gmail.com>},
	VERSION_FROM  => 'lib/MooseX/Role/Defaultable.pm',
	ABSTRACT_FROM => 'lib/MooseX/Role/Defaultable.pm',
	LICENSE             => 'perl',
	META_MERGE => {
		resources => {
			homepage => 'http://github.com/aarondcohen/perl-moosex-role-defaultable',
			repository => 'git://github.com/aarondcohen/perl-moosex-role-defaultable.git',
			bugtracker => 'http://github.com/aarondcohen/perl-moosex-role-defaultable/issues',
		}
	},
);
