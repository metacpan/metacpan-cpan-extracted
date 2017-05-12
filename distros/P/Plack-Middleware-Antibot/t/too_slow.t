use strict;
use warnings;

use Test::More;

use Plack::Middleware::Antibot::TooSlow;

subtest 'sets nothing when GET' => sub {
    my $filter = _build_filter();

    my $env = {
        REQUEST_METHOD          => 'GET',
        'psgix.session'         => {},
        'psgix.session.options' => {}
    };
    $filter->execute($env);

    ok !$env->{'plack.antibot.tooslow.detected'};
};

subtest 'sets session time when GET' => sub {
    my $filter = _build_filter();

    my $env = {
        REQUEST_METHOD          => 'GET',
        'psgix.session'         => {},
        'psgix.session.options' => {}
    };

    $filter->execute($env);

    ok $env->{'psgix.session'}->{antibot_tooslow};
};

subtest 'sets true when no session when POST' => sub {
    my $filter = _build_filter();

    my $env = {
        REQUEST_METHOD          => 'POST',
        'psgix.session'         => {},
        'psgix.session.options' => {}
    };

    $filter->execute($env);

    ok $env->{'plack.antibot.tooslow.detected'};
};

subtest 'sets true when too slow when POST' => sub {
    my $filter = _build_filter();

    my $env = {
        REQUEST_METHOD          => 'POST',
        'psgix.session'         => {antibot_tooslow => 123},
        'psgix.session.options' => {}
    };

    $filter->execute($env);

    ok $env->{'plack.antibot.tooslow.detected'};
};

subtest 'sets false when not slow when POST' => sub {
    my $filter = _build_filter();

    my $env = {
        REQUEST_METHOD          => 'POST',
        'psgix.session'         => {antibot_tooslow => time},
        'psgix.session.options' => {}
    };

    $filter->execute($env);

    ok !$env->{'plack.antibot.tooslow.detected'};
};

sub _build_filter {
    Plack::Middleware::Antibot::TooSlow->new(@_);
}

done_testing;
