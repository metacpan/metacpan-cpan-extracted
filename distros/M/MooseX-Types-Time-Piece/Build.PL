use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MooseX::Types::Time::Piece',
    license             => 'perl',
    dist_author         => q{Steven Lee <stevenl@cpan.org>},
    dist_version_from   => 'lib/MooseX/Types/Time/Piece.pm',
    configure_requires  => {
        'Module::Build' => 0.40,
    },
    build_requires => {
        'Test::More' => 0.68,
        'Test::Fatal' => 0.001,
    },
    requires => {
        'perl' => 5.006,
        'namespace::autoclean' => 0.01,
        'MooseX::Types' => 0.01,
        'MooseX::Types::Moose' => 0.01,
        'Time::Piece' => 1.20,
        'Try::Tiny' => 0.01,
    },
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/MooseX-Types-Time-Piece/',
            bugtracker => 'http://github.com/stevenl/moosex-types-time-piece/issues',
            repository => 'http://github.com/stevenl/moosex-types-time-piece',
        }
    },
    add_to_cleanup => [ 'MooseX-Types-Time-Piece-*' ],
);

$builder->create_build_script();
