#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;

# The Fetch UA options pass through Open::API::Client->new: a cookie_jar
# captures Set-Cookie and replays it on later calls, default headers and the
# agent string ride on every request.

plan skip_all => 'Hyperman not installed' unless eval { require Hyperman; 1 };
plan skip_all => 'Fetch not installed'    unless eval { require Fetch; 1 };
require Open::API;
require Open::API::Plack;
require Open::API::Client;

my $SPEC = {
    openapi => '3.1.0', info => { title => 't', version => '1' },
    paths => {
        '/login'  => { get => { operationId => 'login',
            responses => { 200 => { description => 'ok' } } } },
        '/whoami' => { get => { operationId => 'whoami',
            responses => { 200 => { description => 'ok' } } } },
    },
};

my $port = do {
    my $s = IO::Socket::INET->new(LocalHost => '127.0.0.1', LocalPort => 0,
        Listen => 1, ReuseAddr => 1) or die $!;
    my $p = $s->sockport; close $s; $p;
};
my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDERR, '>', '/dev/null';
    my $api = Open::API->new(spec => $SPEC);
    my $app = Open::API::Plack->new(api => $api, handlers => {
        login  => sub { [ 200, ['Set-Cookie' => 'sid=s3cr3t; Path=/',
                                'Content-Type' => 'application/json'], ['{}'] ] },
        whoami => sub {
            my ($p, $env) = @_;
            [ 200, ['Content-Type' => 'application/json'],
              [ sprintf '{"cookie":"%s","auth":"%s","agent":"%s"}',
                $env->{HTTP_COOKIE} || '', $env->{HTTP_AUTHORIZATION} || '',
                $env->{HTTP_USER_AGENT} || '' ] ];
        },
    })->to_app;
    Hyperman->run(app => $app, host => '127.0.0.1', port => $port, workers => 1);
    exit 0;
}
END { local $?; if ($pid) { kill 'TERM', $pid; waitpid $pid, 0 } }
for (1 .. 50) {
    last if IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
    select undef, undef, undef, 0.1;
}

plan tests => 4;

my $c = Open::API::Client->new(
    spec       => $SPEC,
    base_url   => "http://127.0.0.1:$port",
    cookie_jar => 1,
    headers    => { Authorization => 'Bearer tok123' },
    agent      => 'OA-Test/1.0',
    timeout    => 5,
);

is($c->login->get->{status}, 200, 'login 200 (Set-Cookie captured)');
my $r = $c->whoami->get;
is($r->{data}{cookie}, 'sid=s3cr3t',   'jar replays the cookie');
is($r->{data}{auth},   'Bearer tok123', 'default header on every request');
is($r->{data}{agent},  'OA-Test/1.0',   'agent string sent');
