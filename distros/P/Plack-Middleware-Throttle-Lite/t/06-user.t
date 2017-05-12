use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use t::lib::PMTL;

my $app = builder {
    enable 'Throttle::Lite',
        limits => '2 req/hour', backend => 'Simple', routes => '/api/user';
    t::lib::PMTL::get_app();
};

my %ip_user = (
        #   code  used   limit      expire   content              mime
    '10.13.100.221:ldap'  => [
        1,  200,    1,    2,          '',     'OK',              'text/html',
        2,  200,    2,    2,         '1',     'OK',              'text/html',
        3,  429,    2,    2,         '1',     'Limit Exceeded',  'text/plain',
    ],
    '10.104.52.18:chim' => [
        1,  200,    1,    2,          '',     'OK',              'text/html',
        2,  200,    2,    2,         '1',     'OK',              'text/html',
        3,  429,    2,    2,         '1',     'Limit Exceeded',  'text/plain',
    ],
    '10.104.52.18:root' => [
        1,  200,    1,    2,          '',     'OK',              'text/html',
        2,  200,    2,    2,         '1',     'OK',              'text/html',
        3,  429,    2,    2,         '1',     'Limit Exceeded',  'text/plain',
    ],
);

foreach my $pair (keys %ip_user) {

    my $appx = builder {
        enable sub {
            my ($app) = @_;
            sub {
                my ($env) = @_;
                # fake REMOTE_ADDR + REMOTE_USER
                ($env->{REMOTE_ADDR}, $env->{REMOTE_USER}) = split /:/, $pair;
                $app->($env);
            };
        };
        $app;
    };

    while (my ($num, $code, $used, $limit, $expire_in, $content, $type) = splice(@{ $ip_user{$pair} }, 0, 7)) {
        test_psgi $appx, sub {
            my ($cb) = @_;

            my $reqno = 'Request (' . $num . ') [' . $pair . ']';
            my $res = $cb->(GET '/api/user/login');

            is $res->code,                                  $code,          $reqno . ' code';
            is $res->header('X-Throttle-Lite-Used'),        $used,          $reqno . ' used header';
            is $res->header('X-Throttle-Lite-Limit'),       $limit,         $reqno . ' limit header';
            is !!$res->header('X-Throttle-Lite-Expire'),    $expire_in,     $reqno . ' expire-in header';
            is !!$res->header('Retry-After'),               $expire_in,     $reqno . ' retry-after header';
            like $res->content,                             qr/$content/,   $reqno . ' content';
            is $res->content_type,                          $type,          $reqno . ' content type';
        };
    }
}

done_testing();
