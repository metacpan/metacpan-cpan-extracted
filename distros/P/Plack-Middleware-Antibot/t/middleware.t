use strict;
use warnings;

use Test::More;

use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;

subtest 'init filters' => sub {
    my $app = sub { [200, [], ['Hello']] };

    $app = builder {
        enable 'Antibot', filters => ['FakeField'];
        $app
    };

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET '/');
        is $res->content, 'Hello';

        $res = $cb->(POST '/', {antibot_fake_field => 'bar'});
        is $res->code, 400;
    };
};

subtest 'init filters with params' => sub {
    my $app = sub { [200, [], ['Hello']] };

    $app = builder {
        enable 'Antibot', filters => [['FakeField', field_name => 'foo']];
        $app
    };

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET '/');
        is $res->content, 'Hello';

        $res = $cb->(POST '/', {foo => 'bar'});
        is $res->code, 400;
    };
};

subtest 'returns 200 and set env on fall through' => sub {
    my $app = sub { [200, [], [$_[0]->{'plack.antibot.detected'}]] };

    $app = builder {
        enable 'Antibot',
          filters      => ['FakeField'],
          fall_through => 1;
        $app
    };

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(POST '/', {antibot_fake_field => 'bar'});
        is $res->code,    200;
        is $res->content, 1;
    };
};

subtest 'not set env when custom response' => sub {
    my $app = sub { [200, [], [$_[0]->{'plack.antibot.detected'}]] };

    $app = builder {
        enable 'Session::Cookie', secret  => 123;
        enable 'Antibot',         filters => ['Static'];
        $app
    };

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET '/antibot.css');
        is $res->code,    200;
        is $res->content, '';
    };
};

subtest 'sets single filter score' => sub {
    my $app = sub { [200, [], [$_[0]->{'plack.antibot.score'}]] };

    $app = builder {
        enable 'Antibot',
          filters      => ['FakeField'],
          fall_through => 1;
        $app
    };

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(POST '/', {antibot_fake_field => 'bar'});
        is $res->content, 0.8;
    };
};

subtest 'sets multiple filter score' => sub {
    my $app = sub { [200, [], [$_[0]->{'plack.antibot.score'}]] };

    $app = builder {
        enable 'Session::Cookie', secret => 123;
        enable 'Antibot',
          filters => [['FakeField', score => 0.5], ['Static', score => 0.5]],
          fall_through => 1;
        $app
    };

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(POST '/', {antibot_fake_field => 'bar'});
        is $res->content, 0.75;
    };
};

done_testing;
