use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Safe::Hole',
    VERSION_FROM     => 'lib/Safe/Hole.pm',
    ABSTRACT_FROM    => 'lib/Safe/Hole.pm',
    LICENSE          => 'perl_5',
    AUTHOR           => [
        'Sey Nakajima <nakajima@netstock.co.jp>',
        'Brian McCauley <nobull@cpan.org>',
        'Todd Rinaldo <toddr@cpan.org>',
    ],
    MIN_PERL_VERSION => '5.014',
    INC              => '-I.',
    TEST_REQUIRES    => {
        'Test::More' => '0.40',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/cpan-authors/Safe-Hole',
            bugtracker => {
                web => 'https://github.com/cpan-authors/Safe-Hole/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/cpan-authors/Safe-Hole.git',
                web  => 'https://github.com/cpan-authors/Safe-Hole',
            },
        },
    },
    clean => { FILES => 'Safe-Hole-* *.o' },
);
