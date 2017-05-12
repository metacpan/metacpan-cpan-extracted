use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Parse::cfggen',
    AUTHOR              => q{Mathieu Alorent <kumy@cpan.org>},
    VERSION_FROM        => 'lib/Parse/cfggen.pm',
    ABSTRACT_FROM       => 'lib/Parse/cfggen.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parse-cfggen-*' },
);
