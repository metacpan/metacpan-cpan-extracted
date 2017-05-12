use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::TPP',
    AUTHOR              => q{Matt Vink <matt.vink@gmail.com>},
    VERSION_FROM        => 'lib/Net/TPP.pm',
    ABSTRACT_FROM       => 'lib/Net/TPP.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'LWP' => 1,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-TPP-*' },
);
