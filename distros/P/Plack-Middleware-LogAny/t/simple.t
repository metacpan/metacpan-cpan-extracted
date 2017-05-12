#!env perl

use strict;
use HTTP::Request::Common;
use Log::Any::Test;
use Log::Any qw{$log};
use Plack::Middleware::LogAny;
use Plack::Test;
use Test::More;
use Try::Tiny;

my $messages = [{category => 'plack.test', level => "debug", message => "This is debug"},
                {category => 'plack.test', level => "info", message => "This is info"}];

my $app = sub {
    my ($env) = @_;
    map { $env->{'psgix.logger'}->($_) } @{$messages};
    return [200, [], []];
};

$app = Plack::Middleware::LogAny->wrap ($app, category => 'plack.test');

test_psgi $app, sub {
    my ($cb) = @_;
    my $res = $cb->(GET "/");
    is_deeply ($log->msgs, $messages);
};

done_testing;



