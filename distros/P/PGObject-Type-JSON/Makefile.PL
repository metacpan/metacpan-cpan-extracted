use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PGObject::Type::JSON',
    AUTHOR              => q{Chris Travers <chris.travers@gmail.com>},
    VERSION_FROM        => 'lib/PGObject/Type/JSON.pm',
    ABSTRACT_FROM       => 'lib/PGObject/Type/JSON.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'BSD')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'PGObject'   => 0,
        'JSON'       => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Carp::Always' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PGObject-Type-JSON-*' },
);
