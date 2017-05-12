use Module::Build;

my $build = Module::Build->new(
    module_name => 'Template::Plugin::AudioFile::Info',
    dist_version => '1.05',
    license => 'perl',
    requires => {
        perl            => '5.6.0',
        Template        => 0,
        AudioFile::Info => 0,
    },
    create_makefile_pl => 'traditional'
);

$build->create_build_script;
