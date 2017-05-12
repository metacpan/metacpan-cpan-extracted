use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use t::lib::PMTL;

my $app = builder {
    enable 'Throttle::Lite',
        limits => '2 req/hour', backend => 'Simple', routes => '/api/user', whitelist => [ '10.104.52.18/32' ];
    t::lib::PMTL::get_app();
};

my %ips = (
    '192.168.0.11'  => [
        #   code  content           mime
        1,  200,  'OK',             'text/html',
        2,  200,  'OK',             'text/html',
        3,  429,  'Limit Exceeded', 'text/plain',
    ],
    '10.104.52.18' => [
        #   code  content           mime
        1,  200,  'OK',             'text/html',
        2,  200,  'OK',             'text/html',
        3,  200,  'OK',             'text/html',
    ],
);

foreach my $ipaddr (keys %ips) {
    my $appz = builder {
        # fake REMOTE_ADDR
        enable sub { my ($app) = @_; sub { my ($env) = @_; $env->{REMOTE_ADDR} = $ipaddr; $app->($env) } };
        $app;
    };

    while (my ($num, $code, $content, $type) = splice(@{ $ips{$ipaddr} }, 0, 4)) {
        test_psgi $appz, sub {
            my ($cb) = @_;

            my $reqno = 'Request (' . $num . ') [' . $ipaddr . ']';
            my $res = $cb->(GET '/api/user/login');

            is $res->code,          $code,          $reqno . ' code';
            like $res->content,     qr/$content/,   $reqno . ' content';
            is $res->content_type,  $type,          $reqno . ' content type';
        };
    }
}

done_testing();
