#!/usr/bin/env perl

use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHarness qw(run_request);

use Future::AsyncAwait;
use MIME::Base64 qw(encode_base64);
use PAGI::FastAPI;
use PAGI::FastAPI::Security::HTTPBasic;

my $basic = PAGI::FastAPI::Security::HTTPBasic->new(realm => 'my-api');

my $app = PAGI::FastAPI->new(title => 'HTTPBasic Test');
$app->get('/admin',
    dependencies => [ $basic->depends(key => 'creds') ],
    handler      => async sub ($c) { return $c->stash->{creds} },
);

my $pagi_app = $app->to_app;

sub basic_header ($user, $pass) {
    my $b64 = encode_base64("$user:$pass", '');
    return "Basic $b64";
}

subtest 'valid credentials' => sub {
    my ($status, $data) = run_request($pagi_app,
        method => 'GET', path => '/admin',
        headers => [['Authorization', basic_header('alice', 'sekrit')]],
    );
    is $status, 200, 'request succeeds with valid Basic credentials';
    is $data->{username}, 'alice', 'username extracted correctly';
    is $data->{password}, 'sekrit', 'password extracted correctly';
};

subtest 'password containing a colon is preserved' => sub {
    my ($status, $data) = run_request($pagi_app,
        method => 'GET', path => '/admin',
        headers => [['Authorization', basic_header('bob', 'pa:ss:word')]],
    );
    is $status, 200, 'request succeeds';
    is $data->{password}, 'pa:ss:word', 'only the first colon splits user from password';
};

subtest 'missing Authorization header' => sub {
    my ($status, $data, undef, $headers) = run_request($pagi_app, method => 'GET', path => '/admin');
    is $status, 401, 'missing header is rejected with 401';
    my ($challenge) = map { $_->[1] } grep { lc($_->[0]) eq 'www-authenticate' } @$headers;
    is $challenge, 'Basic realm="my-api"', 'the configured realm is sent in the challenge';
};

subtest 'malformed / non-Basic header' => sub {
    for my $bad ('Bearer abc123', 'Basic', 'Basic ###notbase64###') {
        my ($status) = run_request($pagi_app,
            method => 'GET', path => '/admin',
            headers => [['Authorization', $bad]],
        );
        is $status, 401, "malformed header '$bad' is rejected with 401";
    }
};

done_testing;
