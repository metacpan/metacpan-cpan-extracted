use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Parse::HP::ACU',
    AUTHOR              => q{Jeremy Cole <jeremy@jcole.us>},
    VERSION_FROM        => 'lib/Parse/HP/ACU.pm',
    ABSTRACT_FROM       => 'lib/Parse/HP/ACU.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parse-HP-ACU-*' },
);
