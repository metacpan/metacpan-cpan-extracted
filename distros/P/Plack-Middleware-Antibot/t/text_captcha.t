use strict;
use warnings;

use Test::More;

use HTTP::Request::Common;
use HTTP::Message::PSGI qw(req_to_psgi);
use Plack::Middleware::Antibot::TextCaptcha;

subtest 'sets nothing when GET' => sub {
    my $filter = _build_filter();

    my $env = _build_env(GET '/');

    $filter->execute($env);

    ok !$env->{'plack.antibot.textcaptcha.detected'};
};

subtest 'sets session when GET' => sub {
    my $filter = _build_filter();

    my $env = _build_env(GET '/');

    $filter->execute($env);

    is $env->{'psgix.session'}->{antibot_textcaptcha}, 4;
};

subtest 'sets env when GET' => sub {
    my $filter = _build_filter();

    my $env = _build_env(GET '/');

    $filter->execute($env);

    is $env->{'plack.antibot.textcaptcha.text'}, '2 + 2';
    is $env->{'plack.antibot.textcaptcha.field_name'}, 'antibot_textcaptcha';
};

subtest 'sets true when no session when POST' => sub {
    my $filter = _build_filter();

    my $env = _build_env(POST '/');

    $filter->execute($env);

    ok $env->{'plack.antibot.textcaptcha.detected'};
};

subtest 'sets true when no field when POST' => sub {
    my $filter = _build_filter();

    my $env = _build_env(POST '/', {});

    $filter->execute($env);

    ok $env->{'plack.antibot.textcaptcha.detected'};
};

subtest 'sets true when wrong answer when POST' => sub {
    my $filter = _build_filter();

    my $env = _build_env(POST '/', {antibot_textcaptcha => 'abc'});

    $filter->execute($env);

    ok $env->{'plack.antibot.textcaptcha.detected'};
};

subtest 'sets nothing when POST' => sub {
    my $filter = _build_filter();

    my $env = _build_env(
        POST('/', {antibot_textcaptcha => '123'}),
        'psgix.session' => {antibot_textcaptcha => '123'}
    );

    $filter->execute($env);

    ok !$env->{'plack.antibot.textcaptcha.detected'};
};

sub _build_env {
    my $env = req_to_psgi @_;

    $env->{'psgix.session'}         ||= {};
    $env->{'psgix.session.options'} ||= {};

    $env;
}

sub _build_filter {
    Plack::Middleware::Antibot::TextCaptcha->new(@_);
}

done_testing;
