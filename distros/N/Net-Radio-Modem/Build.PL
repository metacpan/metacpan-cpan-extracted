use 5.010;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::Radio::Modem',
    license             => 'perl',
    dist_author         => q{Jens Rehsack <rehsack@cpan.org>},
    dist_version_from   => 'lib/Net/Radio/Modem.pm',
    build_requires => {
	'Test::Deep' => 0,
        'Test::More' => '0.90',
    },
    configure_requires => {
	'Module::Build' => '0.38',
    },
    requires => {
        'perl' => 5.010,
    },
    add_to_cleanup      => [ 'Net-Radio-Modem-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
