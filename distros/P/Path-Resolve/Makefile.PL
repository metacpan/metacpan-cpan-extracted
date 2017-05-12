use strict;
use ExtUtils::MakeMaker;

my $preop =
    'perldoc -uT $(VERSION_FROM) | tee $(DISTVNAME)/README.pod > README.pod ' .
    '&& pod2text README.pod | tee $(DISTVNAME)/README > README';

WriteMakefile(
    NAME           => 'Path::Resolve',
    VERSION_FROM   => 'lib/Path/Resolve.pm',
    ABSTRACT_FROM  => 'lib/Path/Resolve.pm',
    LICENSE        => 'perl',
    AUTHOR         => 'Mamod Mehyar <mamod.mehyar@gmail.com>',
    META_MERGE => {
        resources => {
            repository => 'git://github.com/mamod/Path-Resolve.git',
            bugtracker => 'https://github.com/mamod/Path-Resolve/issues',
        },
    },
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist      => {
        # COMPRESS => 'gzip -9f',
        # SUFFIX => 'gz',
        PREOP => $preop,
    },
    clean   => { FILES => 'Path-Resolve-*' }
);
