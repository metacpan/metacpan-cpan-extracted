use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MongooseX::JSMethod',
    AUTHOR              => q{Fernando Correa de Oliveira <fernandocorrea@gmail.com>},
    VERSION_FROM        => 'lib/MongooseX/JSMethod.pm',
    ABSTRACT_FROM       => 'lib/MongooseX/JSMethod.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Mongoose'   => 0.11,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MongooseX-JSMethod-*' },
);
