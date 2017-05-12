use Module::Build;
Module::Build->new
    ( module_name => 'Objects::Collection',
    license => 'perl',
    dist_author=>'Zahatski Aliaksandr zag@cpan.org',
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
