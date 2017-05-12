use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::Random::QRBG',
    license             => 'perl',
    dist_author         => 'Brent Garber <overlordq@gmail.com>',
    dist_version_from   => 'lib/Net/Random/QRBG.pm',
    build_requires => {
        'Test::More' => 0,
    },
	requires => {
		'Carp'				=> '>= 1.08',
		'Config'			=> 0,
		'IO::Socket::INET'	=> '>= 1.31',
		'List::Util' 		=> '>= 1.21',
		'bytes'				=> '>= 1.03',
	},
    add_to_cleanup      => [ 'Net-Random-QRBG-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
