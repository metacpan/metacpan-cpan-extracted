use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::embedR',
    license             => 'perl',
    dist_author         => q{Hongwen Qiu <qiuhongwen@gmail.com>},
    dist_version_from   => 'lib/Statistics/embedR.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'                       => '5.010',
        'Statistics::useR'           => 0.01
    },
    add_to_cleanup     => [ 'Statistics-embedR-*' ],
    meta_merge => {
        resources => {
            repository => 'https://github.com/qiuhw/Statistics-embedR',
        }
    },
);

$builder->create_build_script();

# vim: sw=4 ts=4 ft=perl expandtab
