use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::Distribution::Generator',
    AUTHOR              => q{Paul Bennett <paul.w.bennett@gmail.com>},
    VERSION_FROM        => 'lib/Statistics/Distribution/Generator.pm',
    ABSTRACT_FROM       => 'lib/Statistics/Distribution/Generator.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE' => 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Exporter' => '0',
        'List::AllUtils' => '0',
        'overload' => '0',
        'utf8' => '0',
    },
    TEST_REQUIRES => { 'Test::More' => 0, 'Statistics::Descriptive' => '0', },
    MIN_PERL_VERSION => '5.018000',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-Distribution-Generator-*' },
);
