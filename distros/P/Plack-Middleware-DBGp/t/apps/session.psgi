use Plack::Middleware::DBGp (
    debug_client_path        => $ENV{REMOTE_DEBUGGER},
    $ENV{DEBUGGER_PATH} ? (
        client_socket        => $ENV{DEBUGGER_PATH},
    ) : (
        remote_host          => "localhost:" . ($ENV{DEBUGGER_PORT} // 9000),
    ),
    autostart                => 0,
    ide_key                  => 'dbgp_test',
    cookie_expiration        => 1800,
);
use Plack::Builder;

my $app = sub {
    my ($env) = @_;

    return [ 200, [], ["Enabled: ", DB::isConnected() || 0] ];
};

builder {
    enable "DBGp";
    $app;
}
