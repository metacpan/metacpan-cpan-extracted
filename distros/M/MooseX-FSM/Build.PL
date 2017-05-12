use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MooseX::FSM',
    license             => 'perl',
    dist_author         => 'Gordon Irving <goraxe@goraxe.me.uk>',
    dist_version_from   => 'lib/MooseX/FSM.pm',
    build_requires => {
        'Test::More' => 0,
		'Moose'		 => 0.72,
    },
    add_to_cleanup      => [ 'moosex-fsm-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
