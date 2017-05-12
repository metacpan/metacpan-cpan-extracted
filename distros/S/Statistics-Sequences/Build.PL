use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Statistics::Sequences',
    license           => 'perl',
    dist_author       => 'Roderick Garton <rgarton@cpan.org>',
    dist_version_from => 'lib/Statistics/Sequences.pm',
    dist_abstract =>
'Common methods/interface for sub-module sequential tests (of Runs, Joins, etc.)',
    configure_requires => {
        'Module::Build' => 0.421,
    },
    build_requires => {
        'Test::More' => '0.98',
    },
    requires => {
        'Scalar::Util'     => '1.41',
        'Statistics::Data' => '0.11',
        'Statistics::Lite' => '3.2',
        'String::Numeric'  => '0.9',
    },
    add_to_cleanup     => ['Statistics-Sequences-0.15-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
1;
