use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Flute::Style::CSS',
    AUTHOR              => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM        => 'lib/Template/Flute/Style/CSS.pm',
    ABSTRACT_FROM       => 'lib/Template/Flute/Style/CSS.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'CSS::Tiny' => 0,
        'Template::Flute' => 0.0081,
    },
    META_MERGE        => {
        resources => {
            repository  => 'https://github.com/racke/Template-Flute.git',
            bugtracker  => 'https://github.com/racke/Template-Flute/issues',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Flute-Style-CSS*' },
);
