use 5.016;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Regexp::Parser',
    VERSION_FROM      => 'lib/Regexp/Parser.pm', # finds $VERSION
    MIN_PERL_VERSION  => '5.016',
    PREREQ_PM         => { 'parent' => 0 },
    TEST_REQUIRES     => { 'Test::More' => 0 },
    ABSTRACT_FROM  => 'lib/Regexp/Parser.pm', # retrieve abstract from module
    AUTHOR         => 'Jeff japhy Pinyan <japhy@perlmonk.org>',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Regexp-Parser-*' },
    META_MERGE  => {
        build_requires => {
            'Test::More' => 0,  # For testing
        },
        resources => {
            license => 'https://dev.perl.org/licenses/',
            homepage => 'https://github.com/cpan-authors/Regexp-Parser',
            bugtracker => 'https://github.com/cpan-authors/Regexp-Parser/issues',
            repository => 'https://github.com/cpan-authors/Regexp-Parser.git',
        },
    },
);
