use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::Geohash',
    license             => 'perl',
    dist_author         => 'Nick Gerakines <nick@gerakines.net>',
    dist_version_from   => 'lib/Net/Geohash.pm',
    requires => {
        'LWP::UserAgent' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Warn' => 0,
        'Test::Exception' => 0,
    },
    add_to_cleanup      => [ 'Net-Geohash-*' ],
);

$builder->create_build_script();
