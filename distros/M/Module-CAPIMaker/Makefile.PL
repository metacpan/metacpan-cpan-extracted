use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'Module::CAPIMaker',
               VERSION_FROM  => 'lib/Module/CAPIMaker.pm', # finds $VERSION
               PREREQ_PM     => { Text::Template => 1.45 },
               ABSTRACT_FROM => 'lib/Module/CAPIMaker.pm',
               AUTHOR        => 'Salvador Fandiño <sfandino@yahoo.com>',
               EXE_FILES     => [ 'bin/make_perl_module_c_api' ],
               MAN1PODS      => { 'bin/make_perl_module_c_api' => '$(INST_MAN1DIR)/make_perl_module_c_api.1' },
             );
