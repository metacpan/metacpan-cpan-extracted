use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::Zed',
    license             => 'perl',
    dist_author         => q{Roderick Garton <rgarton@cpan.org>},
    dist_version_from   => 'lib/Statistics/Zed.pm',
    dist_abstract       => 'Data-handling and calculations for ratio of observed to standard deviation (zscore)',
    build_requires => {
        'Test::More' => '0.92',
    },
    configure_requires => {
        'Module::Build' => '0.4007',
    },
    requires => {
	    'Math::Cephes' => '0.5303',
        'Scalar::Util' => '1.35',
        'String::Util' => '1.21',
        'Statistics::Lite' => '3.2',
        'Statistics::Data' => '0.08',
    },
    add_to_cleanup      => [ 'Statistics-Zed-0.10-*' ],
    create_makefile_pl => 'traditional',

);

$builder->create_build_script();

1;
