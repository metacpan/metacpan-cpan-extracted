use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Number::Convert::Roman',
    AUTHOR              => q{José Santos <santos.swdev@gmail.com>},
    VERSION_FROM        => 'lib/Number/Convert/Roman.pm',
    ABSTRACT_FROM       => 'lib/Number/Convert/Roman.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Number-Convert-Roman-*' },
);
