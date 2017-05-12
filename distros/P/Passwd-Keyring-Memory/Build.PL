use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Passwd::Keyring::Memory',
    license             => 'perl',
    dynamic_config      => 1,

    build_requires => {
        'Test::More' => 0,
        'Pod::Readme' => 0,
    },
    configure_requires => {
        'Module::Build' => '0.36',
    },
    requires => {
        'perl' => 5.006,
    },

    create_makefile_pl => 'traditional',
    add_to_cleanup      => [ 'Passwd-Keyring-MemoryOnly-*' ],

    create_readme      => 1,
    dist_author         => q{Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>},
    dist_version_from   => 'lib/Passwd/Keyring/Memory.pm',
    meta_merge => {
        keywords => ['keyring', 'passwords' ],
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            homepage    => 'http://bitbucket.org/Mekk/perl-keyring-memory',
            repository => 'http://bitbucket.org/Mekk/perl-keyring-memory',
            bugtracker => 'https://bitbucket.org/Mekk/perl-keyring-memory/issues',
        },
    },
);

$builder->create_build_script();
