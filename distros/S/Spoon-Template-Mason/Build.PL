use strict;

use Module::Build;

Module::Build->new
    ( module_name     => 'Spoon::Template::Mason',
      license         => 'perl',
      requires        => { Spoon         => 0.23,
                           'HTML::Mason' => 1.10,
                         },
      sign            => 1,
      create_makefile_pl => 'passthrough',
    )->create_build_script;
