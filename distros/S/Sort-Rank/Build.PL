use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Sort::Rank',
    sign                => 1,
    license             => 'perl',
    dist_author         => 'Andy Armstrong <andy@hexten.net>',
    dist_version_from   => 'lib/Sort/Rank.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Sort-Rank-*' ],
);

$builder->create_build_script();
