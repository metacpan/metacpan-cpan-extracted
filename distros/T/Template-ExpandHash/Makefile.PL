use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::ExpandHash',
    AUTHOR              => q{Ben Tilly <btilly@gmail.com>},
    VERSION_FROM        => 'lib/Template/ExpandHash.pm',
    ABSTRACT_FROM       => 'lib/Template/ExpandHash.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-ExpandHash-*' },
);
