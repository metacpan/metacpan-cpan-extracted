use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
	NAME          => 'MooseX::Role::Nameable',
	AUTHOR        => q{Aaron Cohen <aarondcohen@gmail.com>},
	VERSION_FROM  => 'lib/MooseX/Role/Nameable.pm',
	ABSTRACT_FROM => 'lib/MooseX/Role/Nameable.pm',
	LICENSE       => 'perl',
	META_MERGE => {
		resources => {
			homepage => 'http://github.com/aarondcohen/perl-moosex-role-nameable',
			repository => 'git://github.com/aarondcohen/perl-moosex-role-nameable.git',
			bugtracker => 'http://github.com/aarondcohen/perl-moosex-role-nameable/issues',
		}
	},
);
