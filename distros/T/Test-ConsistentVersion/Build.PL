use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::ConsistentVersion',
    license             => 'perl',
    dist_author         => 'Glenn Fowler <cebjyre@cpan.org>',
    dist_version_from   => 'lib/Test/ConsistentVersion.pm',
    requires => {
        'Test::Builder' => 0.94,
        'version'       => 0,
        'autodie'       => 0,
    },
    recommends => {
        'Test::Pod::Content'    => 0,
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/cebjyre/Test-ConsistentVersion',
        },
    },
    add_to_cleanup      => [ 'Test-ConsistentVersion-*' ],
);

$builder->create_build_script();
