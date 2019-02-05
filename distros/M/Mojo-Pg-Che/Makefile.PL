use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojo::Pg::Che',
    AUTHOR           => q{Михаил Че (Mikhail Che) <mche[-at-]cpan.org>},
    VERSION_FROM     => 'lib/Mojo/Pg/Che.pm',
    ABSTRACT_FROM    => 'lib/Mojo/Pg/Che.pod',
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
        'Mojo::Pg'              => 4.10,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
          repository => {
            type => 'git',
            url => 'git://github.com/mche/Mojo-Pg-Che.git',
            web => 'https://github.com/mche/Mojo-Pg-Che',
          },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    #~clean => { FILES => 'Mojo-Pg-Che-*' },
);
