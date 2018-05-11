use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Parse::Snort',
    AUTHOR              => 'Richard <perl-cpan@richardharman.com>',
    VERSION_FROM        => 'lib/Parse/Snort.pm',
    ABSTRACT_FROM       => 'lib/Parse/Snort.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp'            => 0,
        'Class::Accessor' => 0,
        'List::Util'      => 1.33,
        'Sub::Util'       => 1.40,
        'Test::Exception' => 0,
        'Test::More'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parse-Snort-*' },
);
