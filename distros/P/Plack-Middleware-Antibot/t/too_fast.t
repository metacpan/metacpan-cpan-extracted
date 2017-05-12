use strict;
use warnings;

use Test::More;

use Plack::Middleware::Antibot::TooFast;

subtest 'sets nothing when GET' => sub {
    my $filter = _build_filter();

    my $env = {
        REQUEST_METHOD          => 'GET',
        'psgix.session'         => {},
        'psgix.session.options' => {}
    };
    $filter->execute($env);

    ok !$env->{'plack.antibot.toofast.detected'};
};

subtest 'sets session time when GET' => sub {
    my $filter = _build_filter();

    my $env = {
        REQUEST_METHOD          => 'GET',
        'psgix.session'         => {},
        'psgix.session.options' => {}
    };

    $filter->execute($env);

    ok $env->{'psgix.session'}->{antibot_toofast};
};

subtest 'sets true when no session when POST' => sub {
    my $filter = _build_filter();

    my $env = {
        REQUEST_METHOD          => 'POST',
        'psgix.session'         => {},
        'psgix.session.options' => {}
    };

    $filter->execute($env);

    ok $env->{'plack.antibot.toofast.detected'};
};

subtest 'sets true when too fast when POST' => sub {
    my $filter = _build_filter();

    my $env = {
        REQUEST_METHOD          => 'POST',
        'psgix.session'         => {antibot_toofast => time},
        'psgix.session.options' => {}
    };

    $filter->execute($env);

    ok $env->{'plack.antibot.toofast.detected'};
};

subtest 'sets false when slow when POST' => sub {
    my $filter = _build_filter();

    my $env = {
        REQUEST_METHOD          => 'POST',
        'psgix.session'         => {antibot_toofast => 123},
        'psgix.session.options' => {}
    };

    $filter->execute($env);

    ok !$env->{'plack.antibot.toofast.detected'};
};

sub _build_filter {
    Plack::Middleware::Antibot::TooFast->new(@_);
}

done_testing;
