use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MooseX::Getopt::Usage',
    license             => 'perl',
    dist_author         => q{Mark Pitchless <markpitchless@gmail.com>},
    dist_version_from   => 'lib/MooseX/Getopt/Usage.pm',
    meta_merge => {
        resources => {
            repository => 'https://github.com/markpitchless/moosex-getopt-usage',
            bugtracker => 'https://github.com/markpitchless/moosex-getopt-usage/issues',
        },
    },
    configure_requires => {
        'Module::Build' => 0.4
    },
    requires => {
        'Moose'           => 1.23,
        'MooseX::Getopt'  => 0,
        'Try::Tiny'       => 0.09,
        'Term::ANSIColor' => 0,
        'Term::ReadKey'   => 0,
        'Text::Wrap'      => 0,
        'File::Basename'  => 0,
        'Pod::Usage'      => 1.36,
        'Pod::Text'       => 0,
        'Module::Loaded'  => 0.06,
        'Moose::Util::TypeConstraints' => 0,
        'FindBin'         => 0,
    },
    build_requires => {
        'File::Slurp'       => 0,
        'Test::Class'       => 0.36,
        'Test::More'        => 0,
        'Test::Differences' => 0.5,
        'Capture::Tiny'     => 0.08,
    },
    add_to_cleanup     => [ 'MooseX-Getopt-Usage-*' ],
    create_makefile_pl => 'small',
);

$builder->create_build_script();
