use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    NAME                => 'RRD::Editor',
    AUTHOR              => q{Doug Leith <dougleith@cpan.org>},
    VERSION_FROM        => 'lib/RRD/Editor.pm',
    ABSTRACT_FROM       => 'lib/RRD/Editor.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
    },
    TEST_REQUIRES => {
        'Test::Deep'    => 0,
        'Test::More'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'RRD-Editor-*' },
);
