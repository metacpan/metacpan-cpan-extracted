use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Normalize',
    license             => 'perl',
    dist_author         => 'Konstantin Kapitanov <perlovik at gmail dot com>',
    dist_version_from   => 'lib/Normalize.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires    => {
    	'Math::Round::Var' => 0,	
    },	
    
    add_to_cleanup      => [ 'Normalize-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
