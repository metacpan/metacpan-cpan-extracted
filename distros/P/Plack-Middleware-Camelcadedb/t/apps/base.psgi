use Plack::Middleware::Camelcadedb (
    remote_host          => "localhost:" . ($ENV{DEBUGGER_PORT} // 23456),
);
use lib 't/apps/lib';
use Plack::Builder;
use App::Base;

builder {
    enable "Camelcadedb";
    \&App::Base::app;
}
