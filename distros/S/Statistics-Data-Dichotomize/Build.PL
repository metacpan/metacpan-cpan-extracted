use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Statistics::Data::Dichotomize',
    license           => 'perl',
    dist_author       => q{Roderick Garton <rgarton@cpan.org>},
    dist_version_from => 'lib/Statistics/Data/Dichotomize.pm',
    dist_abstract =>
'Dichotomize one or more numerical or categorical sequences into a single two-valued sequence',
    configure_requires => {
        'Module::Build' => '0.421',
    },
    build_requires => {
        'Test::More'     => '0.98',
        'Array::Compare' => '2.11',
    },
    requires => {
        'perl'             => 5.006,
        'Number::Misc'     => '1.2',
        'Statistics::Lite' => '3.62',
        'Statistics::Data' => '0.09',
    },
    add_to_cleanup     => ['Statistics-Data-Dichotomize-0.05-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
