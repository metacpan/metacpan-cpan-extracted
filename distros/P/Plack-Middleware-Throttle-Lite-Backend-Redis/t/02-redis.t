use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Redis;

my $default_server = $ENV{REDIS_SERVER} || '127.0.0.1:6379';

my $redis = eval { Redis->new(server => $default_server, debug => 0) };
plan skip_all => "Redis-server needs to be running on '$default_server' for tests" unless $redis;

$redis->select(0);
$redis->flushdb;

# simple application
my $app = sub { [200, [ 'Content-Type' => 'text/html' ], [ '<html><body>OK</body></html>' ]] };

# fixed REMOTE_USER bundle
my $appx = sub {
    my ($limits) = @_;

    builder {
        enable 'Throttle::Lite', limits => $limits, routes => '/api/user',
            backend => [ 'Redis' => { instance => $default_server } ];
        $app;
    };
};

# faked REMOTE_USER bundle
my $appy = sub {
    my ($user) = @_;

    builder {
        enable sub {
            my ($app) = @_;
            sub {
                my ($env) = @_;
                $env->{REMOTE_USER} = $user;
                $app->($env);
            };
        };
        $appx->('5 req/hour');
    };
};

my @samples = (
    #   code  used    expire     content              mime
    1,  200,    1,      '',     'OK',              'text/html',
    2,  200,    2,      '',     'OK',              'text/html',
    3,  200,    3,      '',     'OK',              'text/html',
    4,  200,    4,      '',     'OK',              'text/html',
    5,  200,    5,      '1',    'OK',              'text/html',
    6,  429,    5,      '1',    'Limit Exceeded',  'text/plain',
    7,  429,    5,      '1',    'Limit Exceeded',  'text/plain',
);

my $checks = sub {
    my ($cb, $key, $samples) = @_;

    while (my ($num, $code, $used, $expire_in, $content, $type) = splice(@$samples, 0, 6)) {
        my $reqno = 'Request (' . $num . ') [' . $key . ']';
        my $res = $cb->(GET '/api/user/login');
        is $res->code,                                      $code,          $reqno . ' code';
        is $res->header('X-Throttle-Lite-Used'),            $used,          $reqno . ' used header';
        is defined($res->header('X-Throttle-Lite-Expire')), $expire_in,     $reqno . ' expire-in header';
        is defined($res->header('Retry-After')),            $expire_in,     $reqno . ' retry-after header';
        like $res->content,                                 qr/$content/,   $reqno . ' content';
        is $res->content_type,                              $type,          $reqno . ' content type';
    }
};

# username fixed to 'nobody', limits - vary
my @limits  = ('5 req/hour', '5 req/day');
my %by_limits = map { $_ => [ @samples ] } @limits;
test_psgi $appx->($_), sub { my ($cb) = @_; $checks->($cb, $_, $by_limits{$_}) } for @limits;

# limits fixed to '5 req/hour', users - vary
my @users = qw(Tom Dick Harry);
my %by_users = map { $_ => [ @samples ] } @users;
test_psgi $appy->($_), sub { my ($cb) = @_; $checks->($cb, $_, $by_users{$_}) } for @users;

done_testing();
