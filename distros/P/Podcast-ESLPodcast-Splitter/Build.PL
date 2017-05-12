use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Podcast::ESLPodcast::Splitter',
    license             => 'mit',
    dist_author         => 'Yohei Yamaguchi <joker13meister@gmail.com>',
    dist_version_from   => 'lib/Podcast/ESLPodcast/Splitter.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Podcast-ESLPodcast-Splitter-*' ],
);

$builder->create_build_script();
