use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name  => 'Sort::Bucket',
    dist_author  => 'Nick Cleaton <nick@cleaton.net>',
    all_from     => 'lib/Sort/Bucket.pm',
    license      => 'perl',
    include_dirs => '.',
    requires     => {
        'Exporter' => 0,
        'XSLoader' => 0,
    },
    build_requires => {
        'Devel::Refcount'      => 0,
        'Digest::MD5'          => 0,
        'ExtUtils::CBuilder'   => 0,
        'List::Util'           => 0,
        'Test::Exception'      => 0,
        'Test::Group'          => 0,
        'Test::Group::Foreach' => 0,
        'Test::More'           => 0.88, # Need 0.88 for done_testing()
        'Time::HiRes'          => 0,
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/ncleaton/sort-bucket.git',
        },
    },
    create_makefile_pl => 'small',
);

$builder->create_build_script();
