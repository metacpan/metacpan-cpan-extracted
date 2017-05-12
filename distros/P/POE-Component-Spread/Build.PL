use Module::Build;
my $build = Module::Build->new(
    module_name => 'POE::Component::Spread',
    license => 'perl',
    requires => {
        'POE' => 0,
        'Spread' => 0,
        'Test::More' => 0
    },
    create_makefile_pl => 'passthrough'
);
$build->create_build_script;
