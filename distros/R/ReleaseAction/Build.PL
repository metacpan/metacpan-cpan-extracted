use Module::Build;
Module::Build->new(
  module_name => "ReleaseAction",
  license => 'perl',
  create_makefile_pl => 'traditional',
)->create_build_script;
