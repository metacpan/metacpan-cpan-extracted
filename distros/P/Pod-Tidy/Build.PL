use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name         => 'Pod::Tidy',
    dist_version_from   => 'lib/Pod/Tidy.pm',
    author              => 'Joshua Hoblitt <jhoblitt@cpan.org>',
    license             => 'perl',
    create_makefile_pl  => 'passthrough',
    requires            => {
        'File::Copy'            => 0,
        'IO::String'            => 0,
        'Pod::Find'             => 0,
        'Pod::Simple'           => 0,
        'Pod::Wrap'             => 0,
        'Text::Glob'            => '0.06',
        'Text::Wrap'            => 0,
# CPANPLUS, as of version 0.562, doesn't understand 'build_requires' and
# ignores it.
#    },
#    build_requires      => {
        'Encode'                => 0,
        'Encode::Newlines'      => '0.03',
        'Test::Cmd'             => '1.05',
    },
    recommends          => {
        'Test::Distribution'    => '1.22',
    },
    script_files        => [qw(
        scripts/podtidy
    )],
)->create_build_script;
