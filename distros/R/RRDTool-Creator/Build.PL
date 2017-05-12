use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'RRDTool::Creator',
    license             => 'perl',
    dist_author         => 'Jacquelin Charbonnel <jacquelin.charbonnel at math.cnrs.fr>',
    dist_version_from   => 'lib/RRDTool/Creator.pm',
    requires => {
        'Carp' => 0,
        'RRDTool::OO' => 0.17
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'RRDTool-Creator-*' ],
    'dist_abstract' => 'you bet'
);

$builder->create_build_script();
