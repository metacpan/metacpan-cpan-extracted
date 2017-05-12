use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::DNSbed',
    AUTHOR              => q{Ken Peng <yhpeng@cpan.org>},
    VERSION_FROM        => 'lib/Net/DNSbed.pm',
    ABSTRACT_FROM       => 'lib/Net/DNSbed.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'JSON' => 0,
        'LWP::UserAgent' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-DNSbed-*' },
);
