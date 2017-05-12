use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Parse::AccessLog',
    AUTHOR              => q{Nathan Marley <nathan.marley@gmail.com>},
    VERSION_FROM        => 'lib/Parse/AccessLog.pm',
    ABSTRACT_FROM       => 'lib/Parse/AccessLog.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    BUILD_REQUIRES => {
        'File::Temp' => 0,
        'File::Slurp' => 0,
        'FreezeThaw' => 0,
        'Text::Diff' => 0,
    },
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parse-AccessLog-*' },
);
