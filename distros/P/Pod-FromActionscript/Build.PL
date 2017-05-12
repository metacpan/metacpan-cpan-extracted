use Module::Build;
Module::Build->new(
   module_name => 'Pod::FromActionscript',
   dist_author => 'Clotho Advanced Media, Inc. <cpan@clotho.com>',
   license => 'perl',
   build_requires => {
      'Test::More' => 0,
   },
   script_files => ["script/asdoc2pod"],
   add_to_cleanup => [ 'Pod-FromActionscript-*' ],
)->create_build_script;
