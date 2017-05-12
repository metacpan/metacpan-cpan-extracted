use Plack::Builder;
use File::Basename qw(dirname);

my $handler = sub {
    return [ 404, [ "Content-Type" => "text/plain" ], [ "Not Found" ] ];
};

builder {
    enable "Plack::Middleware::DebugLogging";
    $handler;
};
