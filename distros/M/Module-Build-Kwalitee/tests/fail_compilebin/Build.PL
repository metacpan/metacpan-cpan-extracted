use Module::Build::Kwalitee;
Module::Build::Kwalitee->new(
  dist_name => 'MBKFail',
  dist_version => '0.1',
  script_files => ['failing'],
)->create_build_script;
