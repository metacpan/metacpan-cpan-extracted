use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Remote::Perl',
    VERSION_FROM     => 'lib/Remote/Perl.pm',
    ABSTRACT_FROM    => 'lib/Remote/Perl.pm',
    AUTHOR           => ['Pied Crow <crow@cpan.org>'],
    LICENSE          => 'perl',
    MIN_PERL_VERSION => 'v5.36.0',
    EXE_FILES        => ['bin/remperl'],
    PREREQ_PM        => {},   # all dependencies are core modules
    TEST_REQUIRES    => {
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        no_index    => { directory => ['lib/Remote/Perl'] },
    },
);
