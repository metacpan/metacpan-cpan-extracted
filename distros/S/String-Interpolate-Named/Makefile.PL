use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'String::Interpolate::Named',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION_FROM        => 'lib/String/Interpolate/Named.pm',
    ABSTRACT_FROM       => 'lib/String/Interpolate/Named.pm',
    LICENSE             => 'perl_5',
    PL_FILES            => {},
    MIN_PERL_VERSION    => "5.010001",
    CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker" => 6.5503,
    },
    TEST_REQUIRES  => {
	'Test::More'  => 0,
    },
    META_MERGE => {
     resources => {
	 license    => "http://dev.perl.org/licenses/",
	 repository => "https://github.com/sciurius/perl-String-Interpolate-Named",
	 bugtracker => "https://github.com/sciurius/perl-String-Interpolate-Named/issues",
     },
    },
);
