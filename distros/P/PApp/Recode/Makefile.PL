use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'PApp::Recode',
    VERSION_FROM => 'Recode.pm',
    'PM'	=> {
    		    'Recode.pm'	=> '$(INST_LIBDIR)/Recode.pm',
                   },
    'PREREQ_PM'	=> {
                    Convert::Scalar	=> 0.06,
		   },
);

