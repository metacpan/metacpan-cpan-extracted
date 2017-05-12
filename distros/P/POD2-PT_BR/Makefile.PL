use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POD2::PT_BR',
    AUTHOR              => q{The Brazilian Perl Community},
    VERSION_FROM        => 'lib/POD2/PT_BR.pm',
    ABSTRACT_FROM       => 'lib/POD2/PT_BR.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'POD2::Base' => 0.043,
        'Pod::Perldoc' => 3.15,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POD2-PT_BR-*' },
);
