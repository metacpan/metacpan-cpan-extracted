use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Object::Deadly',
    AUTHOR        => 'Joshua ben Jore <jjore@cpan.org>',
    VERSION_FROM  => 'lib/Object/Deadly.pm',
    ABSTRACT_FROM => 'lib/Object/Deadly.pm',
    PREREQ_PM     => {
        'Carp::Clan'        => 5.4,
        'Devel::StackTrace' => 0,
        'Devel::Symdump'    => 0,
        'Scalar::Util'      => 0,
        'Test::Exception'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Object-Deadly-*' },
);
