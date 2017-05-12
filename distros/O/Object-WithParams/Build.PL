use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Object::WithParams',
    license             => 'perl',
    dist_author         => q{Jaldhar H. Vyas <jaldhar@braincells.com>},
    dist_version_from   => 'lib/Object/WithParams.pm',
    build_requires      => {
        'Test::More' => 0,
    },
    requires            => {
        'perl'       => 5.006,
    },
    add_to_cleanup      => [ 'Object-WithParams-*' ],
    create_makefile_pl  => 'small',
    sign                => 1,
    meta_merge => {
        resources => {
            repository  => 'http://github.com/jaldhar/Object-WithParams',
            homepage    => 'http://jaldhar.github.com/Object-WithParams',
        },
    },
);

$builder->create_build_script();
