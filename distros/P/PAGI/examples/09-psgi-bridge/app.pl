use strict;
use warnings;
use Future::AsyncAwait;
use PAGI::App::WrapPSGI;

my $psgi_app = sub {
    my ($env) = @_;
    my $body = do { local $/; readline $env->{'psgi.input'} } // '';
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ "PSGI says hi\n", "Body: $body" ] ];
};

my $wrapper = PAGI::App::WrapPSGI->new(psgi_app => $psgi_app);
return $wrapper->to_app;
