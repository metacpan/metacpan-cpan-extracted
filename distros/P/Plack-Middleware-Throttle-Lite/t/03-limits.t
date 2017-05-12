use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use t::lib::PMTL;

my $app = sub {
    my ($units, $user) = @_;

    builder {
        # fake REMOTE_USER for each unit
        enable sub {
            my ($app) = @_;
            sub {
                my ($env) = @_;
                $env->{REMOTE_USER} = $user;
                $app->($env);
            };
        };
        enable 'Throttle::Lite',
            limits => '2 ' . $units, backend => 'Simple', routes => '/api/user';
        t::lib::PMTL::get_app();
    };
};

my @samples = (
    #   code  limit used    expire     content              mime
    1,  200,  2,    1,      '',     'OK',              'text/html',
    2,  200,  2,    2,      '1',    'OK',              'text/html',
    3,  429,  2,    2,      '1',    'Limit Exceeded',  'text/plain',
);

# units samples
my %heap = (
    'req/min'       => 'req/min',
    'req/hour'      => 'req/hour',
    'req/day'       => 'req/day',
    'r/m'           => 'req/min',
    'r/h'           => 'req/hour',
    'r/d'           => 'req/day',
    'req/m'         => 'req/min',
    'req/h'         => 'req/hour',
    'req/d'         => 'req/day',
    'r/min'         => 'req/min',
    'r/hour'        => 'req/hour',
    'r/day'         => 'req/day',
    'req per min'   => 'req/min',
    'req per hour'  => 'req/hour',
    'req per day'   => 'req/day',
    'req per m'     => 'req/min',
    'req per h'     => 'req/hour',
    'r per d'       => 'req/day',
    'r per m'       => 'req/min',
    'r per h'       => 'req/hour',
    'r per d'       => 'req/day',
);

# testing against all available limits
foreach my $units (keys %heap) {
    my @t_samples = @samples;

    # some random string for REMOTE_USER
    my @chars = ('a'..'z', 'A'..'Z', '0'..'9');
    my $user = join '', map { @chars[rand @chars] } 1 .. 8;

    test_psgi $app->($units, $user), sub {
        my ($cb) = @_;

        while (my ($num, $code, $limit, $used, $expire_in, $content, $type) = splice(@t_samples, 0, 7)) {
            my $reqno = 'Request (' . $num . ') [' . $units . ']';
            my $res = $cb->(GET '/api/user/login');
            is $res->code,                                  $code,          $reqno . ' code';
            is $res->header('X-Throttle-Lite-Units'),       $heap{$units},  $reqno . ' units header';
            is $res->header('X-Throttle-Lite-Limit'),       $limit,         $reqno . ' limit header';
            is $res->header('X-Throttle-Lite-Used'),        $used,          $reqno . ' used header';
            is !!$res->header('X-Throttle-Lite-Expire'),    $expire_in,     $reqno . ' expire-in header';
            is !!$res->header('Retry-After'),               $expire_in,     $reqno . ' retry-after header';
            like $res->content,                             qr/$content/,   $reqno . ' content';
            is $res->content_type,                          $type,          $reqno . ' content type';
        }
    };
}

done_testing();
