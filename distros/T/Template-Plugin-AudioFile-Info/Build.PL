use Module::Build;

my $build = Module::Build->new(
    module_name => 'Template::Plugin::AudioFile::Info',
    license => 'perl',
    requires => {
        perl            => '5.6.0',
        Template        => 0,
        AudioFile::Info => '2.0.1',
    },
    create_makefile_pl => 'traditional',
    meta_merge => {
        'meta-spec' => { version => 2 },
        resources  => {
            repository => {
                type => 'git',
                url  => 'https://github.com/davorg/template-plugin-audiofile-info.git',
                web  => 'https://github.com/davorg/template-plugin-audiofile-info',
            },
            bugtracker => {
                web  => 'https://github.com/davorg/template-plugin-audiofile-info/issues',
            },
        },
    },
);

$build->create_build_script;
