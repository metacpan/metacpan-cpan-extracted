use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Path::Class::File::Lockable',
    AUTHOR              => 'Peter Karman <perl@peknet.com>',
    VERSION_FROM        => 'lib/Path/Class/File/Lockable.pm',
    ABSTRACT_FROM       => 'lib/Path/Class/File/Lockable.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Path::Class' => 0,
        'File::NFSLock' => 0,
        'Fcntl'         => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Path-Class-File-Lockable-*' },
);
