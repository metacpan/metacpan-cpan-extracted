use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name    => 'SDLx::Widget',
    all_from       => 'lib/SDLx/Widget.pm',
    license        => 'perl',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'SDL'        => '2.523',
        'Test::More' => 0.88,
    },
    requires => {
        'SDL'        => '2.523',
        'Clipboard'  => '0',
        'Mouse'      => '0',
    },
    dist_author   => 'Dustin Mays, garu, Zpmorgan, kthakore, FROGGS',
    meta_merge => {
        resources => {
            bugtracker => 'https://github.com/PerlGameDev/SDLx-Widget/issues',
            repository => 'https://github.com/PerlGameDev/SDLx-Widget'
        }
    },
    create_readme => 1,
)->create_build_script;
