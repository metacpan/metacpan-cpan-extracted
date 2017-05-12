use Plack::Middleware::DBGp (
    debug_client_path        => $ENV{REMOTE_DEBUGGER},
    $ENV{DEBUGGER_PATH} ? (
        client_socket        => $ENV{DEBUGGER_PATH},
    ) : (
        remote_host          => "localhost:" . ($ENV{DEBUGGER_PORT} // 9000),
    ),
    ide_key                  => 'dbgp_test',
);
use lib 't/apps/lib';
use Plack::Builder;
use App::Base;

builder {
    enable "DBGp";
    \&App::Base::app;
}
