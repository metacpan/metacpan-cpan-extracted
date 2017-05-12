use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MojoX::UserAgent',
    AUTHOR              => 'Pascal Gaudette <acajou@gmail.com>',
    VERSION_FROM        => 'lib/MojoX/UserAgent.pm',
    ABSTRACT_FROM       => 'lib/MojoX/UserAgent.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Mojo'       => '0.991250'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MojoX::UserAgent-*' },
);
