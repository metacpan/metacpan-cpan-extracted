use Plack::Builder;
use Plack::App::File;

BEGIN {
    use Plack::Middleware::Profiler::NYTProf;
    $ENV{NYTPROF} = 'start=no:sigexit=int';
    Plack::Middleware::Profiler::NYTProf->preload;
}

my $app = sub {
    my $env = shift;
    return [ '200', [ 'Content-Type' => 'text/plain' ], [ "Hello World" ] ];
};

builder {
    mount "/report" => Plack::App::File->new(root => "./report");
    mount "/" => $app;
};

