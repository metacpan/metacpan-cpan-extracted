use strict;
use Plack::Builder;

my $mongo_options = {
    host    => 'mongodb://mongo.example.com:27017', # subject to change
    db_name => 'sampledb',                          # subject to change
};

builder {
    mount '/' => builder {
        enable 'Debug',
            panels => [
                [ 'Mongo::ServerStatus', connection => $mongo_options ],
                [ 'Mongo::Database', connection => $mongo_options ],
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
