use strict;
use Module::Build;

Module::Build
  ->new( module_name => "Python::Serialise::Pickle",
         license     => 'perl',
         requires    => {
                         'Test::More'   => 0,
                        },
	 create_makefile_pl => 'traditional',
       )
  ->create_build_script;
