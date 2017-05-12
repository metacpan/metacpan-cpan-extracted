use Module::Build;
Module::Build->new(
   module_name => 'Module::License::Report',
   license => 'perl',
   dist_author => 'Clotho Advanced Media, Inc. <cpan@clotho.com>',
   requires => {
      'perl'        => '5.6.0',
      'CPANPLUS'    => '0.051',
      'File::Slurp' => '9999.09',
      'File::Spec'  => 0,
      'YAML'        => 0,
   },
   recommends => {
      'Module::Depends'  => 0,
      'Module::CoreList' => '2.00',
   },
   build_requires => {
      'Test::More' => 0,
      'Test::MockObject' => 0,
   },
   script_files => ['bin/license-report'],
   add_to_cleanup => [ 'Module-License-Report-*' ],
)->create_build_script;
