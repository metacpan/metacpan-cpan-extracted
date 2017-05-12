use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::SSL::AutoCA',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/Net/SSL/AutoCA.pm',
    ABSTRACT_FROM       => 'lib/Net/SSL/AutoCA.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-SSL-AutoCA-*' },
);
