use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'PDL::IO::Touchstone',
    AUTHOR           => q{Eric Wheeler <ewheeler@cpan.org>},
    VERSION_FROM     => 'lib/PDL/IO/Touchstone.pm',
    ABSTRACT_FROM    => 'lib/PDL/IO/Touchstone.pm',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.010',
    META_MERGE => {
	    "meta-spec" => { version => 2 },
	    resources => {
	       homepage => 'https://github.com/KJ7LNW/perl-PDL-IO-Touchstone',
	       bugtracker  => {web=>'https://github.com/KJ7LNW/perl-PDL-IO-Touchstone/issues'},
	       repository  => {
		  url => 'git@github.com:KJ7LNW/perl-PDL-IO-Touchstone.git',
		  type => 'git',
		  web => 'https://github.com/KJ7LNW/perl-PDL-IO-Touchstone.git',
	       },
	       #x_IRC => 'irc://irc.perl.org/#maybe-someday?',
	    },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
	'File::Temp' => '0',
    },
    PREREQ_PM => {
	    'PDL' => '2.080'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PDL-IO-Touchstone-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
