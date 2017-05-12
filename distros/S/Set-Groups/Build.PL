use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Set::Groups',
    license             => 'perl',
    dist_author         => 'Jacquelin Charbonnel <jacquelin.charbonnel at math.cnrs.fr>',
    dist_version_from   => 'lib/Set/Groups.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Set-Groups-*' ],
);

$builder->create_build_script();
