use strict;
use Test::More 0.98;

use Plack::App::JSONRPC;
use Plack::Test;
use HTTP::Request::Common qw(POST);

sub factorial {
    my $num = shift;
    return $num > 1 ? $num * factorial($num - 1) : 1;
}

my $app = Plack::App::JSONRPC->new(
    methods => {
        echo      => sub { $_[0] },
        empty     => sub {''},
        factorial => \&factorial
    }
);

sub json_req {
    POST '/',
      'Content-Type' => 'application/json',
      Content        => shift;
}

my $test = Plack::Test->create($app);
subtest 'echo' => sub {
    my $res = $test->request(
        json_req('{"jsonrpc":"2.0","method":"echo","params":"ok","id":1}'));

    is $res->code, 200, 'request';
    like $res->decoded_content, qr/\Q"result":"ok"\E/, 'response echo';
};

subtest 'notification' => sub {
    my $res = $test->request(
        json_req('{"jsonrpc":"2.0","method":"echo","params":"ok"}'));

    is $res->code, 204, 'response no content';
};

subtest 'empty' => sub {
    my $res = $test->request(
        json_req('{"jsonrpc":"2.0","method":"empty","params":"ok","id":1}'));

    is $res->code, 200, 'request';
    like $res->decoded_content, qr/\Q"result":""\E/, 'response empty';
};

subtest 'factorial' => sub {
    my $res = $test->request(
        json_req('{"jsonrpc":"2.0","method":"factorial","params":5,"id":1}'));

    is $res->code, 200, 'request';
    like $res->decoded_content, qr/\Q"result":120\E/, 'response factorial';
};

done_testing;
