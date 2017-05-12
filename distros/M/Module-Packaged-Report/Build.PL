use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name           => 'Module::Packaged::Report',
    license               => 'perl',
    dist_author           => 'Gabor Szabo',
    create_makefile_pl    => 'traditional',
    create_readme         => 0,
    recursive_test_files  => 0,
    script_files          => [qw(bin/create_package_report.pl)],
    requires              => {
        'Module::Packaged'       => '0.86',
        'Getopt::Long'           => '0',
        'HTML::Template'         => '0',
        'Parse::CPAN::Packages'  => '0',
        'App::Cache'             => '0',
        'YAML'                   => '0',
    },
    build_requires        => {
        'Test::More'                => '0.47',
    },
);

$builder->create_build_script();
