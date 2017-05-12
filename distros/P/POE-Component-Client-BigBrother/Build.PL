use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::Client::BigBrother',
    license             => 'perl',
    dist_author         => q{Sebastien Aperghis-Tramoni <sebastien@aperghis.net>},
    dist_version_from   => 'lib/POE/Component/Client/BigBrother.pm',
    requires => {
        'POE'           => 0,
    },
    build_requires => {
        'Test::More'    => 0,
    },
    add_to_cleanup      => [ 'POE-Component-Client-BigBrother-*' ],
);

$builder->create_build_script();
