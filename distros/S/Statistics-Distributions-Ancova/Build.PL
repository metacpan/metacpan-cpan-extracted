use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::Distributions::Ancova',
    license             => 'perl',
    dist_author         => 'Daniel S. T. Hughes <dsth@cantab.net>',
    dist_version_from   => 'lib/Statistics/Distributions/Ancova.pm',
    dist_abstract       => 'Module to perform one-way Ancova analysis',
    build_requires => {
                            'Test::More' => 0,
    						'Statistics::Distributions' => '1.02',
							'Math::Cephes' 				=> '0.47', 
							'Carp'		 				=> '1.08', 
							'Perl6::Form' 				=> '0.04',
							'Contextual::Return'		=> '0.2.1',
                            'List::Util'                => '1.19', 
                      },
    add_to_cleanup      => [ 'Statistics-Distributions-Ancova-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();













