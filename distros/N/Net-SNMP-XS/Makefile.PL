use ExtUtils::MakeMaker;

use Canary::Stability Net::SNMP::XS => 1, 5.008009;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text XS.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Net::SNMP::XS",
    VERSION_FROM => "XS.pm",
    PREREQ_PM    => {
       Guard     => 1,
       Net::SNMP => 0,
       ExtUtils::MakeMaker => 6.52,
       Canary::Stability   => 0,
    },
);

