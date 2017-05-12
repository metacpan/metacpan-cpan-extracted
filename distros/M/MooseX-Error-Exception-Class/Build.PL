use strict;
use warnings;
use Module::Build 0.33;

my $builder = Module::Build->new(
    module_name         => 'MooseX::Error::Exception::Class',
    license             => 'perl',
    dist_author         => 'Curtis Jewell <csjewell@cpan.org>',
    dist_version_from   => 'lib/MooseX/Error/Exception/Class.pm',
	create_license      => 1,
	create_readme       => 1,
	create_makefile_pl  => 'passthrough',
    configure_requires => {
	    'Module::Build'    => 0.33,
    },
    requires => {
	    'perl'             => 5.008001,
	    'Moose'            => 0.88,
		'Exception::Class' => 1.29,
    },
	build_requires => {
        'Test::More'       => 0.61,
    },
    add_to_cleanup      => [ 'MooseX-Error-Exception-Class-*' ],
);

$builder->create_build_script();
