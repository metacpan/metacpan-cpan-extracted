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
        enable 'AxsLog', combined => 1, response_time => 1, logger => sub { $log .= $_[0] };
        sub{ [ 200, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            chomp $log;
            like $log, qr!^[a-z0-9\.]+ - - \[\d{2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2} [+\-]\d{4}\] "GET / HTTP/1\.1" 200 6 "-" "-" \d+$!;
        };
}

{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', combined => 0, response_time => 0, logger => sub { $log .= $_[0] };
        sub{ [ 200, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            chomp $log;
            like $log, qr!^[a-z0-9\.]+ - - \[\d{2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2} [+\-]\d{4}\] "GET / HTTP/1\.1" 200 6$!;
        };
}


{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', combined => 0, response_time => 1, logger => sub { $log .= $_[0] };
        sub{ [ 200, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            chomp $log;
            like $log, qr!^[a-z0-9\.]+ - - \[\d{2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2} [+\-]\d{4}\] "GET / HTTP/1\.1" 200 6 \d+$!;
        };
}


{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', combined => 0, response_time => 1, logger => sub { $log .= $_[0] };
        sub{
            my $env = shift;
            sub {
                my $responder = shift;
                $responder->([ 200, [], [ "Hello "]]);
            };
        };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            chomp $log;
            like $log, qr!^[a-z0-9\.]+ - - \[\d{2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2} [+\-]\d{4}\] "GET / HTTP/1\.1" 200 6 \d+$!;
        };
}

{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', combined => 0, response_time => 1, logger => sub { $log .= $_[0] };
        sub{
            my $env = shift;
            sub {
                my $responder = shift;
                my $writer = $responder->([ 200, []]);
                $writer->write('Hello ');
                $writer->close;
            };
        };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            chomp $log;
            like $log, qr!^[a-z0-9\.]+ - - \[\d{2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2} [+\-]\d{4}\] "GET / HTTP/1\.1" 200 6 \d+$!;
        };
}


done_testing;

