use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Passwd::Keyring::KDEWallet',
    license             => 'perl',
    dynamic_config      => 1,

    build_requires => {
        'Module::Build' => '0.19', # xs
        'Test::More' => 0,
        'Test::Pod::Coverage' => '1.0',
        'Pod::Readme' => 0,
    },
    configure_requires => {
        'Module::Build' => '0.36',
    },
    requires => {
        'perl' => 5.006,
        'Net::DBus' => 0,
        'Try::Tiny' => 0,
        'Proc::SyncExec' => 1.01,
    },

    share_dir => {
        dist => [ 'example' ],
    },

    create_makefile_pl => 'traditional',
    add_to_cleanup      => [ 'Passwd-Keyring-KDEWallet-*' ],

    create_readme       => 1,
    dist_author         => q{Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>},
    dist_version_from   => 'lib/Passwd/Keyring/KDEWallet.pm',
    meta_merge => {
        keywords => [ qw/ passwords security secure-storage keyring KDE KDEWallet / ],
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            homepage    => 'http://bitbucket.org/Mekk/perl-keyring-kdewallet',
            repository => 'http://bitbucket.org/Mekk/perl-keyring-kdewallet',
            bugtracker => 'https://bitbucket.org/Mekk/perl-keyring-kdewallet/issues',
        },
    },
);

$builder->create_build_script();
