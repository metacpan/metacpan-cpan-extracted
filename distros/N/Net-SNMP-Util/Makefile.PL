use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::SNMP::Util',
    AUTHOR              => q{t.onodera <ong :: garakuta.net>},
    VERSION_FROM        => 'lib/Net/SNMP/Util.pm',
    ABSTRACT_FROM       => 'lib/Net/SNMP/Util.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Exporter'      => 0,
        'Carp'          => 0,
        'List::Util'    => 0,
        'Scalar::Util'  => 0,
        'Net::SNMP'     => 0,
    },

    NO_META             => 1,

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-SNMP-Util-*' },
    ($ExtUtils::MakeMaker::VERSION >= 6.3002? ('LICENSE'=> 'perl') : ()),
);
