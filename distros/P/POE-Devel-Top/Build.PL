use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Devel::Top',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/POE/Devel/Top.pm',
    requires => {
        'POE'               => 0,
        'POE::API::Peek'    => 0,
        'Term::ANSIColor'   => 0,
    },
    build_requires => {
        'Test::More'    => 0,
    },
    add_to_cleanup      => [ 'POE-Devel-Top-*' ],
);

$builder->create_build_script();
