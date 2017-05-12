use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use Test::Exception;
use Plack::Middleware::Throttle::Lite;

can_ok 'Plack::Middleware::Throttle::Lite', qw(
    prepare_app call
    limits maxreq units backend routes
    blacklist whitelist defaults privileged
    header_prefix
);

# simple application
my $app = sub { [ 200, [ 'Content-Type' => 'text/html' ], [ '<html><body>OK</body></html>' ] ] };

#
# catch exception
#

throws_ok { $app = builder { enable 'Throttle::Lite', backend => 'Bogus'; $app } }
    qr|Can't locate Plack.*Bogus\.pm|, 'Unknown non-FQN backend exception';

throws_ok { $app = builder { enable 'Throttle::Lite', backend => [ 'Bogus' => {} ]; $app } }
    qr|Can't locate Plack.*Bogus\.pm|, 'Unknown non-FQN backend exception with options';

throws_ok { $app = builder { enable 'Throttle::Lite', backend => '+My::Own::Bogus'; $app } }
    qr|Can't locate My.*Bogus\.pm|, 'Unknown FQN backend exception';

throws_ok { $app = builder { enable 'Throttle::Lite', backend => { 'Bogus' => {} }; $app } }
    qr|Expected scalar or array reference|, 'Invalid backend configuration exception (hash ref)';

throws_ok { $app = builder { enable 'Throttle::Lite', backend => (bless {}, 'Bogus'); $app } }
    qr|Expected scalar or array reference|, 'Invalid backend configuration exception (blessed ref)';

throws_ok { $app = builder { enable 'Throttle::Lite', routes => {}; $app } }
    qr|Expected scalar, regex or array reference|, 'Invalid routes configuration exception (hash ref)';

throws_ok { $app = builder { enable 'Throttle::Lite', routes => sub {}; $app } }
    qr|Expected scalar, regex or array reference|, 'Invalid routes configuration exception (code ref)';

my $appx = builder {
    enable 'Throttle::Lite',
        limits => '100 req/hour', backend => 'Simple', routes => '/api/user',
        blacklist => [ '127.0.0.9/32', '10.90.90.90-10.90.90.92', '8.8.8.8', '192.168.0.10/31' ];
    $app;
};

#
# catch requsted path
#

my @prepare_tests = (
    (GET '/') => sub {
        is $_->code, 200;
        is $_->content, '<html><body>OK</body></html>';
        ok !defined($_->header('X-Throttle-Lite-Limit'));
        ok !defined($_->header('X-Throttle-Lite-Units'));
    },
    (GET '/api/user/login') => sub {
        is $_->code, 200;
        is $_->header('X-Throttle-Lite-Limit'), 100;
        is $_->header('X-Throttle-Lite-Units'), 'req/hour';
    },
    (GET '/api/host/delete') => sub {
        is $_->code, 200;
        ok !defined($_->header('X-Throttle-Lite-Limit'));
        ok !defined($_->header('X-Throttle-Lite-Units'));
    },
);

while (my ($req, $test) = splice(@prepare_tests, 0, 2) ) {
    test_psgi
        app => $appx,
        client => sub {
            my ($cb) = @_;
            my $res = $cb->($req);
            local $_ = $res;
            $test->($res, $req);
        };
}

#
# blacklisting in action
#

my @ips = (
    '0.0.0.0'      => [ 200, 'OK'          ],
    '127.0.0.1'    => [ 200, 'OK'          ],
    '127.0.0.9'    => [ 403, 'Blacklisted' ],
    '10.90.90.78'  => [ 200, 'OK'          ],
    '10.90.90.90'  => [ 403, 'Blacklisted' ],
    '10.90.90.91'  => [ 403, 'Blacklisted' ],
    '10.90.90.92'  => [ 403, 'Blacklisted' ],
    '8.8.8.8'      => [ 403, 'Blacklisted' ],
    '8.8.4.4'      => [ 200, 'OK'          ],
    '192.168.0.10' => [ 403, 'Blacklisted' ],
    '192.168.0.11' => [ 403, 'Blacklisted' ],
    '192.168.0.12' => [ 200, 'OK'          ],
);

while (my ($ipaddr, $resp) = splice(@ips, 0, 2)) {
    test_psgi
        app => builder {
            enable sub { my ($app) = @_; sub { my ($env) = @_; $env->{REMOTE_ADDR} = $ipaddr; $app->($env) } };
            $appx;
        },
        client => sub {
            my ($cb) = @_;
            my $res = $cb->(GET '/api/user/login');
            is $res->code, $resp->[0], 'Valid code for request from ' . $ipaddr;
            like $res->content, qr/$resp->[1]/, 'Valid content for request from ' . $ipaddr;
        };
}

#
# custom header prefix
#
my $appy = sub {
    my ($prefix) = @_;
    builder {
        enable 'Throttle::Lite', limits => '5 req/hour', routes => '/api/user', header_prefix => $prefix;
        $app;
    }
};

my @headers_tests = (
    '  -[my Cool <thr!ottle> %`"``%% ;=) &]/\'' => 'X-My-Cool-Throttle-Limit',
    ''                                          => 'X-Throttle-Lite-Limit',
    'abc'                                       => 'X-Abc-Limit',
    'w t f ?'                                   => 'X-W-T-F-Limit',
    'tom-dick-harry'                            => 'X-Tomdickharry-Limit',
    'dr. Jekyll / mr. Hyde'                     => 'X-Dr-Jekyll-Mr-Hyde-Limit',
    ':$@! []{} *#`~ ^%"-_ =+?/|\'\\ <>()      ' => 'X-Throttle-Lite-Limit',
    'FSB 66 MHz'                                => 'X-FSB-66-MHz-Limit',
    '3 1415926535 8979323846 2643383279'        => 'X-3-1415926535-8979323846-2643383279-Limit',
    '2.71828182846'                             => 'X-271828182846-Limit',
    'header_prefix'                             => 'X-Headerprefix-Limit',
);

while (my ($prefix, $header) = splice(@headers_tests, 0, 2) ) {
    test_psgi $appy->($prefix), sub {
        my ($cb) = @_;
        my $res = $cb->(GET '/api/user/login');
        ok $res->header($header), 'Limit header is valid for: ' . $prefix;
    };
}

done_testing();
