use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'RPM::Search',
    AUTHOR              => q{Mark Allen <mrallen1@yahoo.com>},
    VERSION_FROM        => 'lib/RPM/Search.pm',
    ABSTRACT_FROM       => 'lib/RPM/Search.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl_5')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DBD::SQLite' => 0,
        'Try::Tiny' => 0,
        'DBI' => 0,
        'File::Find' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'RPM-Search-*' },
    (MM->can('signature_target') ? (SIGN => 1) : ()),
);
