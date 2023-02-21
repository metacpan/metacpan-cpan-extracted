#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Plack::App::ServiceStatus;
use JSON::MaybeXS;

subtest 'basic status data' => sub {

    my $app = Plack::App::ServiceStatus->new(
        app     => 'FakeTest',
        version => 0.42,
    )->to_app;
    my $res    = $app->();                       # "call" app
    my $status = decode_json( $res->[2][0] );    # ugh

    is( $status->{app},     'FakeTest', 'app' );
    is( $status->{version}, '0.42',     'version' );
    ok( $status->{uptime} <= 1, 'uptime' );
    like( $status->{started_at}, qr/^\d+$/,
        'started_at_epoch looks like epoch' );
    like(
        $status->{started_at_iso8601},
        qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$/,
        'started_at looks like ISO8601: '.$status->{started_at_iso8601}
    );
};

done_testing;
