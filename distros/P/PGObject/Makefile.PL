use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.64; # for TEST_REQUIRES ; Since 2012

WriteMakefile(
    NAME                => 'PGObject',
    AUTHOR              => q{Chris Travers <chris.travers@gmail.com>},
    VERSION_FROM        => 'lib/PGObject.pm',
    ABSTRACT_FROM       => 'lib/PGObject.pm',
    MIN_PERL_VERSION    => '5.010',
    PL_FILES            => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'bsd')
      : ()),
    PREREQ_PM           => {
        'Carp::Clan' => 0,
        'DBD::Pg'    => 2.0,
        'Memoize'  => 0,
        'Log::Any' => 0,
        'List::MoreUtils' => 0.07,
                           },
    TEST_REQUIRES       => {
        'Test::More' => 0,
        'Test::Exception' => 0,
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
