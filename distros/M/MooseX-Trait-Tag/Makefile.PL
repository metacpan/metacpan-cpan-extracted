use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
	NAME                => 'MooseX::Trait::Tag',
	AUTHOR              => q{Aaron Cohen <aarondcohen@gmail.com>},
	VERSION_FROM        => 'lib/MooseX/Trait/Tag.pm',
	ABSTRACT_FROM       => 'lib/MooseX/Trait/Tag.pm',
	LICENSE             => 'perl',
	META_MERGE => {
		resources => {
			homepage => 'http://github.com/aarondcohen/perl-moosex-trait-tag',
			repository => 'git://github.com/aarondcohen/perl-moosex-trait-tag.git',
			bugtracker => 'http://github.com/aarondcohen/perl-moosex-trait-tag/issues',
		}
	},
);
