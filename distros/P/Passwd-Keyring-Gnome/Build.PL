use 5.006;
use strict;
use warnings;
use Module::Build;
use ExtUtils::PkgConfig;

#eval { require ExtUtils::PkgConfig; } or
#   die "OS unsupported - no ExtUtils::PkgConfig\n";

my %gnome_keyring_pkg_info;
eval {
    %gnome_keyring_pkg_info = ExtUtils::PkgConfig->find("gnome-keyring-1");
} or die "OS unsupported - need gnome-keyring development libraries\n$@";

my $builder = Module::Build->new(
    module_name         => 'Passwd::Keyring::Gnome',
    license             => 'perl',
    dynamic_config      => 1,

    needs_compiler => 1,
    extra_compiler_flags => $gnome_keyring_pkg_info{cflags},
    extra_linker_flags => $gnome_keyring_pkg_info{libs},

    build_requires => {
        'Module::Build' => '0.19', # xs
        'ExtUtils::CBuilder' => 0,
        'Test::More' => 0,
        'Test::Pod::Coverage' => '1.0',
        'Pod::Readme' => 0,
    },
    configure_requires => {
        'Module::Build' => '0.36',
        'ExtUtils::PkgConfig' => '1.12',
    },
    requires => {
        'perl' => 5.006,
    },

    share_dir => {
        dist => [ 'example' ],
    },

    create_makefile_pl => 'small', # not 'traditional', we test for libraries in Build.pl
    add_to_cleanup      => [ 'Passwd-Keyring-Gnome-*' ],

    create_readme       => 1,
    dist_author         => q{Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>},
    dist_version_from   => 'lib/Passwd/Keyring/Gnome.pm',
    meta_merge => {
        keywords => [ qw/ passwords security secure-storage keyring GNOME seahorse gnome-keyring / ],
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            homepage    => 'http://bitbucket.org/Mekk/perl-keyring-gnome',
            repository => 'http://bitbucket.org/Mekk/perl-keyring-gnome',
            bugtracker => 'https://bitbucket.org/Mekk/perl-keyring-gnome/issues',
        },
    },
);

$builder->create_build_script();
