use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::Strip',
    license             => 'perl',
    dist_author         => 'Thomas Klausner <domm@zsi.at>',
    dist_version_from   => 'lib/Pod/Strip.pm',
    requires => {
        'Test::More' => 0,
        'Pod::Simple' => '3.00',
    },
    add_to_cleanup      => [ 'Pod-Strip-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
