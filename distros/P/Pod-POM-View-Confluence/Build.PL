use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::POM::View::Confluence',
    license             => 'perl',
    dist_author         => 'Philippe Bruhat (BooK) <book@cpan.org>',
    dist_version_from   => 'lib/Pod/POM/View/Confluence.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Pod::POM' => 0.17,
    },
    add_to_cleanup      => [ 'Pod-POM-View-Confluence-*' ],
);

$builder->create_build_script();
