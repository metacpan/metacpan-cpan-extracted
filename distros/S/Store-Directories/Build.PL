use 5.014;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'Store::Directories',
    license             => 'perl_5',
    dist_author         => q{Cameron Tauxe <camerontauxe@gmail.com>},
    dist_version_from   => 'lib/Store/Directories.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
        'Test::Cmd'  => '1.09',
        'IPC::System::Simple' => '1.30'
    },
    requires => {
        'perl'          => '5.014',
        'DBD::SQLite'   => '1.66',
        'Data::UUID'    => '1.226',
        'SQL::SplitStatement'   => '1.00020',
        'IPC::System::Simple'   => '1.30'
    },
    add_to_cleanup     => [ 'Store-Directories-*' ],
    meta_merge => {
        resources => {
            repository => 'https://github.com/camtauxe/store-directories.git'
        }
    }
);

$builder->add_build_element('sql');
$builder->create_build_script();
