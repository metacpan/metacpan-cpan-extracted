use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MooseX::Types::Locale::BR',
    license             => 'perl',
    dist_author         => q{Solli M. Honorio <shonorio@gmail.com>},
    dist_version_from   => 'lib/MooseX/Types/Locale/BR.pm',
    requires => {
        'MooseX::Types' => 0,
        'MooseX::Types::Common::String' => 0,
        'Locale::BR' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'MooseX-Types-Locale-BR-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
