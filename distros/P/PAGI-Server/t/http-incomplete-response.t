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

# An http app that, for /none, RETURNS without ever sending a response. The
# server must treat an incomplete response (no http.response.start) as a protocol
# error and synthesize a 500, rather than dropping the connection with no status
# line at all (which leaves the client with a bare connection close).
my $app = async sub {
    my ($scope, $receive, $send) = @_;
    die "Unsupported scope type: $scope->{type}" if $scope->{type} ne 'http';

    while (1) {
        my $e = await $receive->();
        last if $e->{type} ne 'http.request';
        last unless $e->{more};
    }

    return if ($scope->{path} // '') eq '/none';

    await $send->({ type => 'http.response.start', status => 200, headers => [['content-type','text/plain']] });
    await $send->({ type => 'http.response.body', body => 'ok', more => 0 });
};

subtest 'an app that returns without a response yields 500' => sub {
    my $loop = IO::Async::Loop->new;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $server = PAGI::Server->new(app => $app, host => '127.0.0.1', port => 0, quiet => 1);
    $loop->add($server);
    $server->listen->get;

    my $http = Net::Async::HTTP->new(fail_on_error => 0);
    $loop->add($http);
    my $base = 'http://127.0.0.1:' . $server->port;

    my $ok = $http->GET("$base/ok")->get;
    is($ok->code, 200, '/ok returns 200 (sanity)');

    my $resp = eval { $http->GET("$base/none")->get };
    ok($resp, 'got an HTTP response (server did not just drop the connection)')
        or diag("GET /none failed: $@");
    is($resp->code, 500, 'an incomplete response is turned into a 500') if $resp;

    ok(
        (scalar grep { /without starting a response/i } @warnings),
        'the incomplete response is logged'
    ) or diag("warnings: @warnings");

    $server->shutdown->get;
    $loop->remove($http);
    $loop->remove($server);
};

done_testing;
