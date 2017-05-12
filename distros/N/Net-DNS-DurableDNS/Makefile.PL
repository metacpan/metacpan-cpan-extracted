use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::DNS::DurableDNS',
    AUTHOR              => q{Richard K Bush <rbush@42umbrellas.com>},
    VERSION_FROM        => 'lib/Net/DNS/DurableDNS.pm',
    ABSTRACT_FROM       => 'lib/Net/DNS/DurableDNS.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-DNS-DurableDNS-*' },
);
