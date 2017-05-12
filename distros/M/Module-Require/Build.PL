use Module::Build;

Module::Build -> new(
    module_name => 'Module::Require',
    license => 'perl',
    create_makefile_pl => 'traditional',
) -> create_build_script;
