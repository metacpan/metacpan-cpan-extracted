use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Music::Note::Frequency',
    AUTHOR           => q{Mike Kroh <kroh@cpan.org>},
    VERSION_FROM     => 'lib/Music/Note/Frequency.pm',
    ABSTRACT_FROM    => 'lib/Music/Note/Frequency.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
	'Test::Simple' => 0
    },
    PREREQ_PM => {
	'Music::Note'	=> 0.01
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
	TEST_REQUIRES => {
	'Test::More' => 0,
	'Test::Simple' => 0
	},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Music-Note-Frequency-*' },
);
