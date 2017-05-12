use 5.006; use strict; use warnings;

use Module::Build;

my $builder = Module::Build->new(

    module_name => 'MooseX::OmniTrigger',
    license     => 'perl',

    dist_abstract     => 'Recursion-proof attribute triggers that fire on any initialize, set, or clear operation.',
    dist_author       => 'Todd Lorenz <trlorenz@hotmail.com>',
    dist_version_from => 'lib/MooseX/OmniTrigger.pm',

    build_requires => {

        'Test::Exception' => 0,
        'Test::More'      => 0,
    },

    requires => {

        'Hash::Util::FieldHash' => 0,
        'Moose'                 => 2.0200,
        'namespace::autoclean'  => 0,
    },

    add_to_cleanup => ['MooseX-OmniTrigger-*'],

    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
