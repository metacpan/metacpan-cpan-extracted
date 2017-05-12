use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::IPAddress::Util',
    AUTHOR              => q{Paul Bennett <paul.w.bennett@gmail.com>},
    VERSION_FROM        => 'lib/Net/IPAddress/Util.pm',
    ABSTRACT_FROM       => 'lib/Net/IPAddress/Util.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp' => '0',
        'Exporter' => '0',
        'List::MoreUtils' => '0',
        'Math::BigInt' => '0',
        'overload' => '0',
        'utf8' => '0',
    },
    TEST_REQUIRES => { 'Test::More' => 0, 'Time::HiRes' => '0', },
    MIN_PERL_VERSION => '5.010000',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-IPAddress-Util-*' },
);
