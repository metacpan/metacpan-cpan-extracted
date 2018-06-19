use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PGObject::Type::ByteString',
    AUTHOR              => q{Erik Huelsmann <ehuels@gmail.com>},
    VERSION_FROM        => 'lib/PGObject/Type/ByteString.pm',
    ABSTRACT_FROM       => 'lib/PGObject/Type/ByteString.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'BSD')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'PGObject'  => '1.403.2',
        'DBD::Pg'   => '1.20',
        'Ref::Util' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'File::Slurp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PGObject-Type-ByteString-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/ledgersmb/PGObject-Type-ByteString.git',
                 web  => 'https://github.com/ledgersmb/PGObject-Type-ByteString',
             },
         },
    },
);
