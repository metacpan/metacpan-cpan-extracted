use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Padre::Plugin::HG',
    AUTHOR              => q{Michael Mueller <michael@muellers.net.au>},
    VERSION_FROM        => 'lib/Padre/Plugin/HG.pm',
    ABSTRACT_FROM       => 'lib/Padre/Plugin/HG.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Padre-Plugin-HG-*' },
);
