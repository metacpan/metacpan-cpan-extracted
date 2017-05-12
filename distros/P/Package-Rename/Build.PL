use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Package::Rename',
	license             => 'perl',
	dist_author         => 'Leon Timmermans <leont@cpan.org>',
	dist_version_from   => 'lib/Package/Rename.pm',
	build_requires      => {
		'Test::More'    => 0,
	},
	requires            => {
		perl            => 5.006,
		'MRO::Compat'   => 0,
	},
	add_to_cleanup      => [ 'Package-Rename-*' ],
	create_makefile_pl  => 'traditional',
	sign	            => 1,
);

$builder->create_build_script();
