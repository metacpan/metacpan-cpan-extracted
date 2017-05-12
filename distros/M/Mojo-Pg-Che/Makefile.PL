use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojo::Pg::Che',
    AUTHOR           => q{Михаил Че (Mikhail Che) <mche[-at-]cpan.org>},
    VERSION_FROM     => 'lib/Mojo/Pg/Che.pm',
    ABSTRACT_FROM    => 'lib/Mojo/Pg/Che.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    # MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Mojo::Pg'              => 3.01,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    #~clean => { FILES => 'Mojo-Pg-Che-*' },
);
