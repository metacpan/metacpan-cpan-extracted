use strict;
use warnings;
use Module::Build;

# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name        => 'Perl::Metrics::Simple',
    license            => 'perl',
    configure_requires => { 'Module::Build' => 0.40 },
    requires           => {
        'Carp'                      => 0,
        'Data::Dumper'              => 0,
        'File::Basename'            => 0,
        'File::Find'                => 1.01,
        'Getopt::Long'              => 0,
        'IO::File'                  => 1.14,
        'Readonly'                  => 1.03,
        'PPI'                       => 1.113,
        'Statistics::Basic::StdDev' => 0,
        'Statistics::Basic::Mean'   => 0,
        'Statistics::Basic::Median' => 0,
        'Pod::Usage'                => 0,
    },
    recommends => {
        'Readonly::XS' => 1.02,                 # Speeds up Readonly scalars
    },
    build_requires => {
        'Data::Dumper'        => 0,
        'File::Spec'          => 0,
        'Module::Build'       => 0.2612,
        'Readonly'            => 1.03,
        'Test::Compile'       => 'v1.1.0',
        'Test::Pod'           => 1.00,
        'Test::Pod::Coverage' => 1.04,
    },
    script_files => { 'bin/countperl' => 1, },
    add_to_cleanup => [ '*.tar.gz', 'Makefile', 'Makefile.old' ],
    meta_merge     => {
        resources => {
                repository =>  'https://github.com/matisse/Perl-Metrics-Simple',
                bugtracker =>  'https://github.com/matisse/Perl-Metrics-Simple/issues',
            },
    },
)->create_build_script;
