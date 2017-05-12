use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'PApp::I18n',
    VERSION_FROM => 'I18n.pm',
    'PM'	=> {
    		    'I18n.pm'	=> '$(INST_LIBDIR)/I18n.pm',
                   },
);

