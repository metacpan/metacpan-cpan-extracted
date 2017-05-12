use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Run::Env',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jozef@kutej.net>',
    dist_version_from   => 'lib/Run/Env.pm',
    requires => {
    	'Carp::Clan'      => 0,
    	'List::MoreUtils' => 0,
    	'Carp::Clan'      => 0,
    	'File::Spec'      => 0,
    	'FindBin::Real'   => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Run-Env-*' ],
    create_makefile_pl  => 'traditional',
    sign                => 1,
    create_readme       => 1,
);

$builder->create_build_script();
