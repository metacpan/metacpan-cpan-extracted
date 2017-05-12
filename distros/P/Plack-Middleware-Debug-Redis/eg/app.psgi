use Plack::Builder;

my $redis_host = 'localhost:6379'; # subject to change

builder {
    mount '/' => builder {
        enable 'Debug',
            panels => [
                [ 'Redis::Info', instance => $redis_host ],
                [ 'Redis::Keys', instance => $redis_host, db => 0 ],
            ];
        sub {
            [
                200,
                [ 'Content-Type' => 'text/html' ],
                [ '<html><body>OK</body></html>' ]
            ];
        };
    };
};
