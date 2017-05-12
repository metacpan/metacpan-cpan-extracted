use strict;
use warnings;

use Test::Spec;

use_ok 'Nginx::Runner::Config';

describe 'Nginx::Runner::Config' => sub {
    it 'should encode simple directives' => sub {
        my $config =
          [[worker_processes => 1], [error_log => '/var/log/nginx.error']];

        is Nginx::Runner::Config::encode($config), <<'CONFIG';
worker_processes 1;
error_log /var/log/nginx.error;
CONFIG
    };

    it 'should encode block directives' => sub {
        my $config = [
            [   server => [
                    [listen   => 8080],
                    [location => '/' => [[proxy_pass => "http://127.0.0.1"]]]
                ]
            ]
        ];

        is Nginx::Runner::Config::encode($config), <<'CONFIG';

server {
    listen 8080;

    location / {
        proxy_pass http://127.0.0.1;
    }
}
CONFIG
    };
};

runtests unless caller;
