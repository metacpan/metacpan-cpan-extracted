use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Net::Async::HTTP;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PAGI::Server;

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';

# Minimal HTTP responder used by the apps below.
async sub respond_ok {
    my ($scope, $receive, $send) = @_;
    while (1) {
        my $event = await $receive->();
        last if $event->{type} ne 'http.request';
        last unless $event->{more};
    }
    await $send->({ type => 'http.response.start', status => 200, headers => [] });
    await $send->({ type => 'http.response.body', body => 'ok', more => 0 });
}

subtest "lifespan_mode 'on' makes a startup decline fatal" => sub {
    my $loop = IO::Async::Loop->new;

    # An app that declines lifespan by raising (the canonical decline idiom).
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        die "this app does not implement lifespan" if $scope->{type} eq 'lifespan';
        return await respond_ok($scope, $receive, $send);
    };

    my $server = PAGI::Server->new(
        app => $app, host => '127.0.0.1', port => 0, quiet => 1,
        lifespan_mode => 'on',
    );
    $loop->add($server);

    my $err = dies { $server->listen->get };
    ok($err, "server refused to start when lifespan_mode='on' and the app declined");

    $loop->remove($server);
};

subtest "lifespan_mode 'off' skips the lifespan scope entirely" => sub {
    my $loop = IO::Async::Loop->new;

    my %seen;
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        $seen{ $scope->{type} }++;
        return await respond_ok($scope, $receive, $send) if $scope->{type} eq 'http';
        die "Unsupported scope type: $scope->{type}";
    };

    my $server = PAGI::Server->new(
        app => $app, host => '127.0.0.1', port => 0, quiet => 1,
        lifespan_mode => 'off',
    );
    $loop->add($server);
    $server->listen->get;

    ok($server->is_running, 'server started with lifespan_mode=off');

    my $http = Net::Async::HTTP->new;
    $loop->add($http);
    my $resp = $http->GET('http://127.0.0.1:' . $server->port . '/')->get;
    is($resp->code, 200, 'HTTP still works with lifespan off');

    ok(!$seen{lifespan}, 'the app was never invoked with a lifespan scope');
    ok($seen{http},      'the app was invoked with an http scope');

    $server->shutdown->get;
    $loop->remove($http);
    $loop->remove($server);
};

subtest 'an invalid lifespan_mode is rejected at construction' => sub {
    my $err = dies {
        PAGI::Server->new(app => sub { }, lifespan_mode => 'bogus');
    };
    ok($err, 'construction failed');
    like($err, qr/lifespan_mode/, 'error names the offending option');
};

done_testing;
