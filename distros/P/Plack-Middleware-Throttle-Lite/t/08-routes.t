use strict;
use warnings;
use Test::More;
use Test::Exception;
use Plack::Builder;
use t::lib::PMTL;

my %good_routes = (
    scalar       => '/api/user',
    regex        => qr{^/api},
    aof_scalars  => [ '/api/user', '/api/host' ],
    aof_regexs   => [ qr{^/api/user}, qr{^/api/host} ],
    mixed        => [ qr{^/api/(user|host)}, '/api/item', qr{^/api/user/log(in|out)} ],
);

my %bad_routes = (
    hashref      => { '/api/user' => '/user/host' },
    coderef      => sub { qr{^/api} },
    scalarref    => \'/api/item',
);

my $app = sub {
    my ($routes) = @_;

    builder {
        enable 'Throttle::Lite', limits => '1000 req/hour', routes => $routes;
        t::lib::PMTL::get_app();
    };
};

for my $rkind (keys %good_routes) {
    lives_ok { $app->($good_routes{$rkind}) }               "routes as $rkind lives";
}

for my $rkind (keys %bad_routes) {
    throws_ok { $app->($bad_routes{$rkind}) }
        qr/Expected scalar, regex or array reference/,      "routes as $rkind throws";
}

done_testing;
