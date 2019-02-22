#!/usr/bin/env perl

use Dancer;
use Plack::Builder;

{
    package UsageMetrics;
    use Dancer ':syntax';

    get '/record/123' => sub {
        return "View this record";
    };

    get '/download/987' => sub {
        return "Successfully downloaded";
    };

    get '/matomo' => sub {
        status 200;
    };

    1;
}

my $app = sub {
    my $env     = shift;
    my $request = Dancer::Request->new(env => $env);
    Dancer->dance($request);
};


builder {
    enable "Plack::Middleware::Matomo",
        id_site => "my_repo",
        base_url => "http://localhost:5000/matomo",
        # api_key => "secr3t",
        view_paths => ['record/(\w+)/*'],
        download_paths => ['download/(\w+)/*'],
        oai_identifier_format => 'oai:test.server.org:%s',
        ;
    $app;
};
