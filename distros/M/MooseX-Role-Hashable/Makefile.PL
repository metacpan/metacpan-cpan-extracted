use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
	NAME          => 'MooseX::Role::Hashable',
	AUTHOR        => q{Aaron Cohen <aarondcohen@gmail.com>},
	VERSION_FROM  => 'lib/MooseX/Role/Hashable.pm',
	ABSTRACT_FROM => 'lib/MooseX/Role/Hashable.pm',
	LICENSE       => 'perl',
	META_MERGE => {
		resources => {
			homepage => 'http://github.com/aarondcohen/perl-moosex-role-hashable',
			repository => 'git://github.com/aarondcohen/perl-moosex-role-hashable.git',
			bugtracker => 'http://github.com/aarondcohen/perl-moosex-role-hashable/issues',
		}
	},
);
