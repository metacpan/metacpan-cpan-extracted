use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PGObject',
    AUTHOR              => q{Chris Travers <chris.travers@gmail.com>},
    VERSION_FROM        => 'lib/PGObject.pm',
    ABSTRACT_FROM       => 'lib/PGObject.pm',
    PL_FILES            => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'bsd')
      : ()),
    PREREQ_PM           => { 
                           'DBD::Pg'    => 2.0,
                           'Test::More' => 0,
                           'Try::Tiny' => 0,
                           'Test::Exception' => 0,
                           'Memoize'  => 0,
                           },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PGObject-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/ledgersmb/PGObject.git',
                 web  => 'https://github.com/ledgersmb/PGObject',
             },
         },
    },
);
