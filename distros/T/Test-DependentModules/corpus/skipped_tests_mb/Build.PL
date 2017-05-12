use Module::Build;
Module::Build->new(
   module_name => 'MyModule',
   dist_abstract => 'my module',
)->create_build_script;
