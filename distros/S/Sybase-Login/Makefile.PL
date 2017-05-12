use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => "Sybase::Login",
	      PM => { 'Login.pm' => '$(INST_LIBDIR)/Login.pm' },
              VERSION_FROM => 'Login.pm',
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
             );
