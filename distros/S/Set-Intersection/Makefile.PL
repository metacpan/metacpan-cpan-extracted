use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Set::Intersection',
    AUTHOR              => 'turugina <turugina@cpan.org>',
    VERSION_FROM        => 'lib/Set/Intersection.pm',
    ABSTRACT_FROM       => 'lib/Set/Intersection.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'  => 0,
        'Exporter'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Set-Intersection-*' },
);
