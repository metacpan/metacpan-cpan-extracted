use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Perlbal::Control',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Perlbal/Control.pm',
    build_requires => {
        'Test::More' => 0,
        'Moose'      => '0.32',
        'MooseX::Control' => '0.02',
        'Proc::ProcessTable' => 0,
    },
    add_to_cleanup      => [ 'Perlbal-Control-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
