use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Net::Whois::IANA',
	license             => 'perl',
	dist_author         => q{Roman M. Parparov <roman@parparov.com>},
	dist_version_from   => 'lib/Net/Whois/IANA.pm',
	build_requires => {
        	'Test::More' => 0,
	},
	requires => {
		'Net::CIDR'  => 0,
		'IO::Socket' => 0,
	},
	add_to_cleanup      => [ 'Net-Whois-IANA-*' ],
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
