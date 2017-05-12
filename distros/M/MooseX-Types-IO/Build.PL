use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MooseX::Types::IO',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/MooseX/Types/IO.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Exception' => '0.27',
        'MooseX::Types' => 0,
        'IO' => 0,
        'IO::String' => 0,
        'IO::All'    => 0,
    },
    add_to_cleanup      => [ 'MooseX-Types-IO-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
