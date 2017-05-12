use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Module::Build::JSAN',
    license            => 'perl',
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    requires           => {
                            'Module::Build' => '0.2701',
                            'Pod::Select' => '1.3',
                            'Pod::Simple::HTML' => '3.01',
                            'Pod::Simple::Text' => '2.02',
                            'Pod::Stripper' => '0.22',
                            'Pod::Simple' => '3.02',
    },
    auto_features => {
        JSON_support => {
            description => "Can write fully-functional META.json files",
            requires    => { JSON => '2.00' },
        },
    },
);
$build->create_build_script;
