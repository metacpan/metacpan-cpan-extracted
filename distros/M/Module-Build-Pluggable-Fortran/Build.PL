use Module::Build;
my $build = Module::Build->new(
    module_name   => 'Module::Build::Pluggable::Fortran',
    license       => 'perl',
    create_readme => 1,

    configure_requires => {
        'Module::Build' => '0.4005',
    },

    requires => {
        'perl'                           => '5.008',
        'Module::Build::Pluggable::Base' => 0,
        'ExtUtils::F77'                  => 0,
        'Text::ParseWords'               => 0,
    },

    test_requires => {
        'Test::More'      => 0.87,
        'IPC::Cmd'        => 0,
        'Path::Class'     => 0,
        'List::MoreUtils' => 0,
    },

    meta_merge => {
        resources => {
            bugtracker =>
              'https://github.com/mvgrimes/mb-pluggable-fortran/issues',
            repository => 'http://github.com/mvgrimes/mb-pluggable-fortran'
        }
    },
);

$build->create_build_script;
