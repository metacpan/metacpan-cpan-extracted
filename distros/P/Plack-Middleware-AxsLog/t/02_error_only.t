use strict;
use warnings;
use HTTP::Request::Common;
use HTTP::Message::PSGI;
use Plack::Builder;
use Plack::Test;
use Test::More;

{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', error_only => 1, logger => sub { $log .= $_[0] };
        sub{ [ 200, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            chomp $log;
            ok !$log, 'a';
        };
}

{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', error_only => 1, logger => sub { $log .= $_[0] };
        sub{ [ 404, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            chomp $log;
            ok $log, 'b';
        };
}

{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', long_response_time => 500_000, logger => sub { $log .= $_[0] };
        sub{ [ 200, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            chomp $log;
            ok !$log, 'c';
        };
}

{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', long_response_time => 500_000, logger => sub { $log .= $_[0] };
        sub{ sleep 1; [ 200, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            chomp $log;
            ok $log, 'd';
        };
}

{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', error_only => 1, long_response_time => 500_000, logger => sub { $log .= $_[0] };
        sub{ sleep 1; [ 200, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            chomp $log;
            ok $log, 'e';
        };
}

{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', error_only => 1, long_response_time => 1_500_000, logger => sub { $log .= $_[0] };
        sub{ sleep 1; [ 500, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            chomp $log;
            ok $log, 'f';
        };
}

{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', error_only => 1, long_response_time => 500_000, logger => sub { $log .= $_[0] };
        sub{ sleep 1; [ 500, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            chomp $log;
            ok $log, 'g';
        };
}

{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', error_only => 1, long_response_time => 5_000_000, logger => sub { $log .= $_[0] };
        sub{ sleep 1; [ 200, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            chomp $log;
            ok !$log, 'h';
        };
}


done_testing;

