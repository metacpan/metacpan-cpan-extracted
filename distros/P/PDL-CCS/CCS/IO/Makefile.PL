use ExtUtils::MakeMaker;
require "../../pdlmaker.plm";
pdlmaker_init();

WriteMakefile(
	      NAME=>'PDL::CCS::IO::FastRaw',
	      VERSION_FROM => '../../CCS.pm',
	      LICENSE => 'perl',
	      #PM => { (map {$_=>"\$(INST_LIBDIR)/CCS/$_"} <*.pm>), },
	      DIR =>[],
	      PREREQ_PM => {
			    'PDL' => 0,
			   },
	      CONFIGURE_REQUIRES => {
				     'PDL'=>0,
				     'ExtUtils::MakeMaker'=>0,
				    },
	      clean => { FILES => "t/ccs.* t/ccs3.* t/dense.* t/dense3.*" },
	     );
