use strict;
use warnings;

use Test::More;

use HTTP::Request::Common;
use HTTP::Message::PSGI qw(req_to_psgi);
use Plack::Middleware::Antibot::FakeField;

subtest 'sets nothing when not POST' => sub {
    my $filter = _build_filter();

    my $env = req_to_psgi GET '/';
    $filter->execute($env);

    ok !$env->{'plack.antibot.fakefield.detected'};
};

subtest 'sets nothing when field not present' => sub {
    my $filter = _build_filter();

    my $env = req_to_psgi POST '/', {foo => 'bar'};
    $filter->execute($env);

    ok !$env->{'plack.antibot.fakefield.detected'};
};

subtest 'sets true when field present' => sub {
    my $filter = _build_filter();

    my $env = req_to_psgi POST '/', {antibot_fake_field => 'bar'};
    $filter->execute($env);

    ok $env->{'plack.antibot.fakefield.detected'};
};

subtest 'sets env vars' => sub {
    my $filter = _build_filter();

    my $env = req_to_psgi GET '/';
    $filter->execute($env);

    is $env->{'plack.antibot.fakefield.field_name'}, 'antibot_fake_field';
    like $env->{'plack.antibot.fakefield.html'}, qr/<label>/;
};

sub _build_filter {
    Plack::Middleware::Antibot::FakeField->new(@_);
}

done_testing;
