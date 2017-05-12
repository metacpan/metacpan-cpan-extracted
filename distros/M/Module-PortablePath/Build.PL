use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
				 module_name         => 'Module::PortablePath',
				 dist_author         => 'Roger M Pettett <rpettett@cpan.org>',
				 dist_version_from   => 'lib/Module/PortablePath.pm',
				 dist_abstract       => 'Module::PortablePath - host-independent library paths',
				 license             => 'perl',
				 configure_requires  => {
							 'Module::Build' => 0.38,
							},
				 requires            => {
							 'Config::IniFiles' => 2.38,
							},
				 build_requires      => {
							 'Test::More'    => 0,
							 },
				 build_recommends    => {
							 'Test::Pod::Coveragre' => '1.00',
							 'Test::Pod'            => '1.00',
							 'Test::Distribution'   => 0,
							 'Test::Perl::Critic'   => 0,
							},
				);

$builder->create_build_script();
