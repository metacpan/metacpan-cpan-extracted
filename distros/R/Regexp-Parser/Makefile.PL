use 5.006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Regexp::Parser',
    VERSION_FROM      => 'lib/Regexp/Parser.pm', # finds $VERSION
    PREREQ_PM         => { NEXT => '' }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'lib/Regexp/Parser.pm', # retrieve abstract from module
    AUTHOR         => 'Jeff japhy Pinyan <japhy@perlmonk.org>',
    PREREQ_PM => {
	'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Regexp-Parser-*' },
    META_MERGE  => {
        build_requires => {
            'Test::More' => 0,  # For testing
        },
        resources => {
            license => 'http://dev.perl.org/licenses/',
            homepage => 'http://wiki.github.com/toddr/Regexp-Parser',
            bugtracker => 'https://github.com/toddr/Regexp-Parser/issues',
            repository => 'http://github.com/toddr/Regexp-Parser/tree/master',
#            MailingList => 'http://groups.google.com/group/Regexp-Parser',
        },
    },
);
