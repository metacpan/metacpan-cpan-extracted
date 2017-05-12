use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Padre::Plugin::Shell::Base',
    AUTHOR              => q{Gregory Siems <gsiems@gmail.com>},
    VERSION_FROM        => 'lib/Padre/Plugin/Shell/Base.pm',
    ABSTRACT_FROM       => 'lib/Padre/Plugin/Shell/Base.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Padre'      => 0.43,
        'File::Temp' => 0,
        'YAML'       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Padre-Plugin-Shell-Base-*' },
);
