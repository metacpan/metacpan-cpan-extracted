use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sledge::Plugin::QueryHash',
    AUTHOR              => 'syushi matsumoto <matsumoto@alink.co.jp>',
    VERSION_FROM        => 'lib/Sledge/Plugin/QueryHash.pm',
    ABSTRACT_FROM       => 'lib/Sledge/Plugin/QueryHash.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sledge-Plugin-QueryHash-*' },
);
