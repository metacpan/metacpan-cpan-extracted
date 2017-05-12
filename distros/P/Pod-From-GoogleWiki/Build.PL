use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::From::GoogleWiki',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Pod/From/GoogleWiki.pm',
    build_requires => {
        'Test::More' => 0,
        'Text::SimpleTable' => 0,
    },
    add_to_cleanup      => [ 'Pod-From-GoogleWiki-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
