use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
	NAME          => 'MooseX::Role::UnsafeConstructable',
	AUTHOR        => q{Aaron Cohen <aarondcohen@gmail.com>},
	VERSION_FROM  => 'lib/MooseX/Role/UnsafeConstructable.pm',
	ABSTRACT_FROM => 'lib/MooseX/Role/UnsafeConstructable.pm',
	LICENSE       => 'perl',
	META_MERGE => {
		resources => {
			homepage => 'http://github.com/aarondcohen/perl-moosex-role-unsafeconstructable',
			repository => 'git://github.com/aarondcohen/perl-moosex-role-unsafeconstructable.git',
			bugtracker => 'http://github.com/aarondcohen/perl-moosex-role-unsafeconstructable/issues',
		}
	},
);
