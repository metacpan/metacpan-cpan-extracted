use ExtUtils::MakeMaker;

use Canary::Stability Superluminal => 0, 5.010;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Superluminal.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Superluminal",
    VERSION_FROM => "Superluminal.pm",
    PREREQ_PM => {
       common::sense => 3.75,
       AnyEvent => 7.18, # for handle->error
    },
    CONFIGURE_REQUIRES => {
       "ExtUtils::MakeMaker" => 6.6,
       "Canary::Stability" => 0,
    },
    META_MERGE => {
       "meta-spec" => { version => 2},
       preqreqs => {
          runtime => {
             recommends => {
                Coro => 6,
             },
          },
       },
    },
);

