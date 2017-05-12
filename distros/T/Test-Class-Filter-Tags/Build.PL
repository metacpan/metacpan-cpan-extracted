use Module::Build;

my $build = Module::Build->new(
    module_name         => 'Test::Class::Filter::Tags',
    license             => 'perl',
    requires            => {
        'Attribute::Method::Tags'   => 0.10,
        'Test::Class'               => 0.36,
    },
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
);

$build->create_build_script;
