use Plack::Builder;

BEGIN {
    use Plack::Middleware::Profiler::NYTProf;
    $ENV{NYTPROF} = 'start=no:sigexit=int';
    Plack::Middleware::Profiler::NYTProf->preload;
}

my $app = sub {
    my $env = shift;
    sleep_a_while();
    return [ '200', [ 'Content-Type' => 'text/plain' ], [ "Hello World" ] ];
};

sub sleep_a_while {
    sleep 1;
}

builder {
    enable "Plack::Middleware::Profiler::NYTProf";
    $app;
};
