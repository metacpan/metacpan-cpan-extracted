use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Scalar::MoreUtils',
    license             => 'perl',
    dist_author         => 'Robert Krimen <rkrimen@cpan.org>',
    dist_version_from   => 'lib/Scalar/MoreUtils.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Scalar-MoreUtils-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
