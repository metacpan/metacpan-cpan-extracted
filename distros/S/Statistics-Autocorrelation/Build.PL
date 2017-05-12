use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::Autocorrelation',
    license             => 'perl',
    dist_author         => q{Roderick Garton <rgarton@cpan.org>},
    dist_abstract       => 'Coefficients for any lag, as correlogram, with significance tests',
    dist_version_from   => 'lib/Statistics/Autocorrelation.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4007',
    },
    build_requires => {
        'Test::More' => '0.92',
        'Math::Cephes' => '0.5303',
        'Statistics::Data' => '0.08',
        'Statistics::Lite' => '3.2',
        'Statistics::Zed' => '0.072',
        'List::AllUtils' => '0.07', # "AllUtils" in case later versions require more than in "Utils" itself
    },
    requires => {
        'Math::Cephes' => '0.5303',
        'Statistics::Data' => '0.08',
        'Statistics::Lite' => '3.2',
        'Statistics::Zed' => '0.10',
        'List::AllUtils' => '0.07',
    },
    add_to_cleanup      => [ 'Statistics-Autocorrelation-0.06-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
1;
