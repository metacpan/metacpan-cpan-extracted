use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Module::Replace',
    license             => 'perl',
    dist_author         => 'Darin McBride <dmcbride@cpan.org>',
    dist_version_from   => 'lib/Module/Replace.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Module-Replace-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
