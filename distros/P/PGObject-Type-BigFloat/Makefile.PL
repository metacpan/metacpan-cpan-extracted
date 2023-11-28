use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PGObject::Type::BigFloat',
    AUTHOR              => q{Chris Travers <chris.travers@gmail.com>},
    VERSION_FROM        => 'lib/PGObject/Type/BigFloat.pm',
    ABSTRACT_FROM       => 'lib/PGObject/Type/BigFloat.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'BSD')
      : ()),
    PL_FILES            => {},
    PREREQ_PM           => {
                           'PGObject'       => 0,
                           'Math::BigFloat' => '1.999842',
                           },
    BUILD_REQUIRES	=> { 'Test::More'     => 0, },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PGObject-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/ledgersmb/PGObject-Type-BigFloat.git',
                 web  => 'https://github.com/ledgersmb/PGObject-Type-BigFloat',
             },
         },
    },
);
