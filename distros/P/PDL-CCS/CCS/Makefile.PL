use ExtUtils::MakeMaker;
require "../pdlmaker.plm";
pdlmaker_init();

WriteMakefile(
              NAME=>'PDL::CCS::Nd',
              VERSION_FROM => '../CCS.pm',
              LICENSE => 'perl',
              #PM => { (map {$_=>"\$(INST_LIBDIR)/CCS/$_"} <*.pm>), },
              DIR =>[
                     #'Old',
                     'Utils',
                     'Ufunc',
                     'Ops',
                     'MatrixOps',
                     'IO',
                    ], ##-- debug#2
              PREREQ_PM => {
                            'PDL' => 0,
                            'PDL::VectorValued' => '1.0.4',
                           },
              CONFIGURE_REQUIRES => {
                                     'PDL'=>0,
                                     'ExtUtils::MakeMaker'=>0,
                                    },
             );
