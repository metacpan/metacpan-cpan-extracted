use strict;
use warnings;

use Test::More;

use HTTP::Request::Common;
use HTTP::Message::PSGI qw(req_to_psgi);
use Plack::Middleware::Antibot::Static;

subtest 'sets nothing when GET' => sub {
    my $filter = _build_filter();

    my $env = _build_env(GET '/');

    $filter->execute($env);

    ok !$env->{'plack.antibot.static.detected'};
};

subtest 'returns style when GET' => sub {
    my $filter = _build_filter();

    my $env = _build_env(GET '/antibot.gif');

    my $res = $filter->execute($env);

    is $res->[0], 200;
    is_deeply $res->[2], [''];
};

subtest 'sets session when GET' => sub {
    my $filter = _build_filter();

    my $env = _build_env(GET '/antibot.gif');

    $filter->execute($env);

    ok $env->{'psgix.session'}->{antibot_static};
};

subtest 'sets env vars' => sub {
    my $filter = _build_filter();

    my $env = _build_env(GET '/');

    $filter->execute($env);

    is $env->{'plack.antibot.static.path'}, '/antibot.gif';
    is $env->{'plack.antibot.static.html'},
      '<img src="/antibot.gif" width="1" height="1" style="display:none" />';
};

subtest 'sets true when no session when POST' => sub {
    my $filter = _build_filter();

    my $env = _build_env(POST '/');

    $filter->execute($env);

    ok $env->{'plack.antibot.static.detected'};
};

subtest 'sets true when expired when POST' => sub {
    my $filter = _build_filter();

    my $env =
      _build_env(POST('/', {}), 'psgix.session' => {antibot_static => 123});

    $filter->execute($env);

    ok $env->{'plack.antibot.static.detected'};
};

subtest 'sets nothing when POST' => sub {
    my $filter = _build_filter();

    my $env =
      _build_env(POST('/', {}), 'psgix.session' => {antibot_static => time});

    $filter->execute($env);

    ok !$env->{'plack.antibot.static.detected'};
};

sub _build_env {
    my $env = req_to_psgi @_;

    $env->{'psgix.session'}         ||= {};
    $env->{'psgix.session.options'} ||= {};

    $env;
}

sub _build_filter {
    Plack::Middleware::Antibot::Static->new(@_);
}

done_testing;
