use Module::Build;
my $build = Module::Build->new(
    module_name   => 'Module::Build::Pluggable::PDL',
    license       => 'perl',
    create_readme => 1,

    configure_requires => {
        'Module::Build' => '0.4005',
    },

    requires => {
        'Module::Build::Pluggable::Base' => 0,
        'PDL'                            => '2.000',
        'PDL::Core::Dev'                 => 0,
        'PDL::PP'                        => 0,
        'List::MoreUtils'                => 0,
        'Pod::Perldoc'                   => 0,
    },

    test_requires => {
        'Test::More'  => 0.87,
        'IPC::Cmd'    => 0,
        'Path::Class' => 0,
    },

    meta_merge => {
        resources => {
            bugtracker =>
              'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Build-Pluggable-PDL',
            repository => 'http://github.com/mvgrimes/mb-pluggable-pdl'
        }
    },
);

$build->create_build_script;
