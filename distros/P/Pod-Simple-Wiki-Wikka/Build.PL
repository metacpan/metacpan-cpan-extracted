use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Pod::Simple::Wiki::Wikka',
      license         => 'perl',
      dist_author     => 'Daniel Staal - <DStaal@usa.net>',
      dist_abstract   => 'A class for creating Pod to WikkiWiki filters.',
      create_readme   => 1,
      dynamic_config  => 0,
      create_makefile_pl => 'traditional',

      requires        => { 'Pod::Simple::Wiki' => 0 },
    )->create_build_script;
