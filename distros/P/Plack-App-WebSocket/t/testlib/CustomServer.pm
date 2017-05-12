package testlib::CustomServer;
use strict;
use warnings;
use Test::More;
use testlib::Util qw(set_timeout run_server);

use Plack::App::WebSocket;
use AnyEvent::WebSocket::Server;
use AnyEvent;
use AnyEvent::Handle;
use Protocol::WebSocket::Handshake::Client;

sub _get_raw_handshake_response {
    my ($port) = @_;
    my $response_cv = AnyEvent->condvar;
    my $raw_req = Protocol::WebSocket::Handshake::Client->new(url => "ws://127.0.0.1:$port/")->to_string;
    my $read_buf = "";
    my $handle; $handle = AnyEvent::Handle->new(
        connect => ["127.0.0.1", $port],
        on_connect => sub {
            my ($handle) = @_;
            $handle->push_write($raw_req);
            $handle->push_shutdown;
        },
        on_error => sub {
            my ($handle, $fatal, $message) = @_;
            fail("AnyEvent::Handle error: fatal=$fatal, message=$message");
        },
        on_read => sub {
            my ($handle) = @_;
            $read_buf .= $handle->{rbuf};
            $handle->{rbuf} = "";
        },
        on_eof => sub {
            $response_cv->send($read_buf);
            undef $handle;
        }
    );
    return $response_cv;
}

sub run_tests {
    my ($server_runner) = @_;
    set_timeout;
    my @got_success_env = ();
    my @got_error_env = ();
    my $planned_exception = undef;
    my $app = Plack::App::WebSocket->new(
        websocket_server => AnyEvent::WebSocket::Server->new(
            handshake => sub {
                my ($req, $res) = @_;
                $res->subprotocol('my.websocket.subprotocol');
                if(defined($planned_exception)) {
                    die $planned_exception;
                }
                return $res;
            }
        ),
        on_establish => sub {
            my ($conn, $psgi_env) = @_;
            push @got_success_env, $psgi_env;
            undef $conn;
        },
        on_error => sub {
            my ($psgi_env) = @_;
            push @got_error_env, $psgi_env;
            return [400, ['Content-Type: text/plain'], ["on_error is called"]];
        }
    );
    my ($port, $server_guard) = run_server($server_runner, $app->to_app);

    {
        note("--- customize handshake response");
        $planned_exception = undef;
        @got_success_env = @got_error_env = ();
        my $got_res = _get_raw_handshake_response($port)->recv;
        like $got_res, qr/Sec-WebSocket-Protocol\s*:\s*my\.websocket\.subprotocol/, "setting subprotocol OK";
        is scalar(@got_error_env), 0, "no error";
        is scalar(@got_success_env), 1, "one successful connection";
    }
    
    {
        note("--- user-defined exception from handshake process");
        $planned_exception = "This is user-defined exception";
        @got_success_env = @got_error_env = ();
        my $got_res = _get_raw_handshake_response($port)->recv;
        like $got_res, qr/on_error is called/, "error response ok";
        is scalar(@got_success_env), 0, "no successful connection";
        is scalar(@got_error_env), 1, "single call to on_error";
        is $got_error_env[0]{"plack.app.websocket.error"}, "invalid request";
        like $got_error_env[0]{"plack.app.websocket.error.handshake"}, qr/This is user-defined exception/;
    }
}

1;
