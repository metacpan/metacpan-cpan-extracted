use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Parse::GutenbergRoget',
    AUTHOR              => 'Ricardo Signes <rjbs@semiotic.systems>',
    VERSION_FROM        => 'lib/Parse/GutenbergRoget.pm',
    ABSTRACT_FROM       => 'lib/Parse/GutenbergRoget.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'   => 0,
        'Text::CSV_XS' => 0,
    },
    META_MERGE => {
      resources => {
        license     => 'http://dev.perl.org/licenses/',
        repository  => 'https://github.com/rjbs/Parse-GutenbergRoget',
      },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parse-GutenbergRoget*' },
);
