use Module::Build;

my $build = Module::Build->new(
    module_name => 'Template::Plugin::AudioFile::Info',
    license => 'perl',
    requires => {
        perl            => '5.6.0',
        Template        => 0,
        AudioFile::Info => '2.0.1',
    },
    create_makefile_pl => 'traditional'
);

$build->create_build_script;
