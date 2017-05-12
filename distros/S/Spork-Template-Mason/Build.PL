use Module::Build;

Module::Build->new
    ( module_name     => 'Spork::Template::Mason',
      license         => 'perl',
      requires        => { 'Spoon::Template::Mason' => 0.03 },
      sign            => 1,
      create_makefile_pl => 'passthrough',
    )->create_build_script;
