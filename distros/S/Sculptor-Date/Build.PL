use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Sculptor::Date',
    license             => 'perl',
    dist_author         => 'Damon Allen Davison <allolex@cpan.org>',
    dist_version_from   => 'lib/Sculptor/Date.pm',
    requires => {
        'Date::Calc' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Sculptor-Date-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
