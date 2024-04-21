use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'PDL::Opt::Simplex::Simple',
    AUTHOR           => q{Eric Wheeler <ewheeler@cpan.org>},
    VERSION_FROM     => 'lib/PDL/Opt/Simplex/Simple.pm',
    ABSTRACT_FROM    => 'lib/PDL/Opt/Simplex/Simple.pm',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.010',
    META_MERGE => {
	    "meta-spec" => { version => 2 },
	    resources => {
	       homepage => 'https://github.com/KJ7LNW/perl-PDL-Opt-Simplex-Simple',
	       bugtracker  => {web=>'https://github.com/KJ7LNW/perl-PDL-Opt-Simplex-Simple/issues'},
	       repository  => {
		  url => 'git://github.com/KJ7LNW/perl-PDL-Opt-Simplex-Simple.git',
		  type => 'git',
		  web => 'https://github.com/KJ7LNW/perl-PDL-Opt-Simplex-Simple.git',
	       },
	       #x_IRC => 'irc://irc.perl.org/#maybe-someday?',
	    },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
	'Math::Round' => 0,
	'PDL' => '2.056',
	'Parallel::Pipes' => '0.200'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PDL-Opt-Simplex-Simple-*' },
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
