use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::Radio::Modem::Adapter::oFono',
    license             => 'perl',
    dist_author         => q{Jens Rehsack <rehsack@cpan.org>},
    dist_version_from   => 'lib/Net/Radio/Modem/Adapter/oFono.pm',
    build_requires => {
        'Test::More' => 0.90,
    },
    requires => {
        'perl' => 5.010,
	'Net::Radio::Modem' => 0.001,
	'Net::Radio::oFono' => 0.001,
    },
    add_to_cleanup      => [ 'Net-Radio-Modem-Adapter-oFono-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
