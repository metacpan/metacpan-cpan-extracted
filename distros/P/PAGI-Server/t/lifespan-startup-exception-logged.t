use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Future::AsyncAwait;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PAGI::Server;

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';

# An app that RAISES during lifespan startup (e.g. a failed DB connect) declines
# lifespan, and the server continues without it. But the exception text must
# appear in the log -- not be buried under a generic "not supported" string --
# so a genuine startup failure that is being treated as "unsupported" is visible
# to an operator.
my $app = async sub {
    my ($scope, $receive, $send) = @_;

    if ($scope->{type} eq 'lifespan') {
        await $receive->();    # lifespan.startup
        die "could not connect to database\n";
    }

    await $send->({ type => 'http.response.start', status => 200, headers => [] });
    await $send->({ type => 'http.response.body', body => '' });
};

subtest 'a lifespan startup exception is logged with its message' => sub {
    my $loop = IO::Async::Loop->new;

    my @logged;
    local $SIG{__WARN__} = sub { push @logged, $_[0] };

    # Not quiet: the "lifespan not supported" notice is info-level and must emit.
    my $server = PAGI::Server->new(app => $app, host => '127.0.0.1', port => 0);
    $loop->add($server);
    $server->listen->get;    # app raises during startup -> unsupported, server starts

    ok($server->is_running, 'server started (lifespan treated as unsupported)');

    ok(
        (scalar grep { /could not connect to database/ } @logged),
        'the startup exception message appears in the log'
    ) or diag("captured: @logged");

    $server->shutdown->get;
    $loop->remove($server);
};

done_testing;
