use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'TAIR::GeneDescriptions',
    AUTHOR              => q{Haktan Suren <hsuren@cpan.org>},
    VERSION_FROM        => 'lib/TAIR/GeneDescriptions.pm',
    ABSTRACT_FROM       => 'lib/TAIR/GeneDescriptions.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'LWP::UserAgent' => 0,
        'HTTP::Request::Common' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'TAIR-GeneDescriptions-*' },
);
