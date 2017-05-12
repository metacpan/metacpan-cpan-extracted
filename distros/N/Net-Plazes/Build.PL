use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
				 module_name         => 'Net::Plazes',
				 dist_author         => 'Roger M Pettett <rpettett@cpan.org>',
				 dist_version_from   => 'lib/Net/Plazes.pm',
				 dist_abstract       => q[Net::Plazes - An interface to Plazes.net services],
				 license             => 'perl',
				 requires            => {
							 'Class::Accessor'     => '0.31',
							 'English'             => '1.01',
							 'Carp'                => '1.02',
							 'Lingua::EN::Inflect' => '1.89',
							 'XML::LibXML'         => '1.66',
							 'strict'              => '1.04',
							 'warnings'            => '1.06',
							 'base'                => '2.13',
							 'HTTP::Request'       => '5.814',
							 'LWP::UserAgent'      => '5.814',
							 'XML::LibXML'         => '1.66',
							},
				 recommends          => {
							},
				 build_requires      => {
							 'Test::More'          => '0.8',
							 'Test::Trap'          => '0.1.1',
							},
				 build_recommends    => {
							 'Test::Distribution' => '0',
							 'Test::Perl::Critic' => '0',
							},
				 create_makefile_pl  => 'passthrough',
				);

$builder->create_build_script();
