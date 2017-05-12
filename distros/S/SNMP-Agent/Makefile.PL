use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SNMP::Agent',
    AUTHOR              => q{Alexander Else <aelse@else.id.au>},
    VERSION_FROM        => 'lib/SNMP/Agent.pm',
    ABSTRACT_FROM       => 'lib/SNMP/Agent.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'NetSNMP::agent' => 0,
        'NetSNMP::ASN' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SNMP-Agent-*' },
);
