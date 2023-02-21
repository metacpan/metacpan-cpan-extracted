#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Plack::App::ServiceStatus;
use JSON::MaybeXS;

subtest 'get buildinfo' => sub {

    my $app = Plack::App::ServiceStatus->new(
        app       => 'FakeTest',
        version   => 0.42,
        buildinfo => './t/buildinfo.json'
    )->to_app;
    my $res = $app->(); # "call" app
    my $status = decode_json( $res->[2][0] );    # ugh

    ok( $status->{buildinfo}, 'status has buildinfo' );
    is( $status->{buildinfo}{branch}, 'main',
        'buildinfo contains branch=main' );
    is(
        $status->{buildinfo}{commit},
        '589bf76c122c26c859553bc40f0c9dc253ea89a3',
        'buildinfo contains commit=589bf76c122c26c859553bc40f0c9dc253ea89a3'
    );
};

subtest 'bad buildinfo file' => sub {

    my $app = Plack::App::ServiceStatus->new(
        app       => 'FakeTest',
        version   => 0.42,
        buildinfo => './t/NOPE.json'
    )->to_app;
    my $res = $app->(); # "call" app

    my $status = decode_json( $res->[2][0] );    # ugh

    ok( $status->{buildinfo}, 'status has buildinfo' );
    is( $status->{buildinfo}{status}, 'error',
        'buildinfo has error' );
    like(
        $status->{buildinfo}{message},
        qr/cannot read buildinfo from/,
        'buildinfo error message'
    );
};

subtest 'invalid buildinfo file' => sub {

    my $app = Plack::App::ServiceStatus->new(
        app       => 'FakeTest',
        version   => 0.42,
        buildinfo => './t/buildinfo-broken.json'
    )->to_app;
    my $res = $app->(); # "call" app

    my $status = decode_json( $res->[2][0] );    # ugh

    ok( $status->{buildinfo}, 'status has buildinfo' );
    is( $status->{buildinfo}{status}, 'error',
        'buildinfo has error' );
    ok(
        $status->{buildinfo}{message},
        'buildinfo error message'
    );
};

done_testing;
