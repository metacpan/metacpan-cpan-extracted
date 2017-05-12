use Module::Build::Kwalitee;
Module::Build::Kwalitee->new(
  module_name => 'MBKFail',
  requires => { 'perl' => '5.8.1' },
)->create_build_script;
