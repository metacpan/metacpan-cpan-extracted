use strict;
use Module::Build;

Module::Build
  ->new( module_name => "Python::Serialise::Marshal",
         license     => 'perl',
         requires    => {
			 'Math::Complex' => 0,
			 'File::Binary'  => "1.0",
                         'Test::More'    => 0,
                        },
	 create_makefile_pl => 'traditional',
       )
  ->create_build_script;



