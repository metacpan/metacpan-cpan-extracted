use ExtUtils::MakeMaker;

use Canary::Stability String::CRC32C => 1, 5.008;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text CRC32C.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "String::CRC32C",
    VERSION_FROM => "CRC32C.pm",
    CONFIGURE_REQUIRES => {
       "ExtUtils::MakeMaker" => 6.6,
       "Canary::Stability" => 0,
    },
    BUILD_REQUIRES => {
       ExtUtils::ParseXS => 3.28,
    },
);

