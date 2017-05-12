use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Number::Phone::AU',
    AUTHOR              => q{Josh Heumann <cpan@joshheumann.com>},
    VERSION_FROM        => 'lib/Number/Phone/AU.pm',
    ABSTRACT_FROM       => 'lib/Number/Phone/AU.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Most' => 0,
        'Mouse'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Number-Phone-AU-*' },
);
