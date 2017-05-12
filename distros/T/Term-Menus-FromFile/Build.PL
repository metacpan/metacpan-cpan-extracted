use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Term::Menus::FromFile',
      license         => 'perl',
      dist_author     => 'Daniel T. Staal <DStaal@usa.net>',
      requires        => {  'Term::Menus' => '0'
                           ,'perl' => '5.6.0'
                         },
      build_requires  => {  'Test::Builder::Tester' => '0'
                           ,'Test::More' => '0'
                         },
      dist_version    => '1.0.0',
      dist_abstract   => q(Creates 'Term::Menus' menus from external files.),	
    )->create_build_script;
