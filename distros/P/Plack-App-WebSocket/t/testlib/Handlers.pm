package testlib::Handlers;
use strict;
use warnings;
use Test::More;
use testlib::Util qw(set_timeout run_server);
use AnyEvent::WebSocket::Client;
use AnyEvent;

use Plack::App::WebSocket;

my @received_messages = ();
my @finish_tokens = ();
my $port;
my $cv_finish;

sub _test_case {
    my ($label, $exp_received_messages, $exp_finish_tokens, $code) = @_;
    note("--- $label");
    @received_messages = ();
    @finish_tokens = ();
    $cv_finish = AnyEvent->condvar;
    my $client = AnyEvent::WebSocket::Client->new;
    my $conn = $client->connect("ws://127.0.0.1:$port/")->recv;
    $code->($conn);
    undef $conn;
    $cv_finish->recv;
    is_deeply(\@received_messages, $exp_received_messages, "$label: received messages OK");
    is_deeply(\@finish_tokens, $exp_finish_tokens, "$label: finish event handlers OK") or diag(explain \@finish_tokens);
}

sub run_tests {
    my ($server_runner) = @_;
    note("you can set multiple event handlers to a single event, and they are called in the same order.");
    
    set_timeout;
    my $app = Plack::App::WebSocket->new(on_establish => sub {
        my ($conn, $env) = @_;
        is(ref($env), "HASH", "env must be a hash-ref");
        $cv_finish->begin;
        $conn->on(message => sub {
            my ($conn, $msg) = @_;
            push(@received_messages, "1:$msg");
            $conn->send($msg);
        });
        $conn->on(message => sub {
            my ($inner_conn, $msg) = @_;
            push(@received_messages, "2:$msg");
            if($msg eq "quit") {
                $inner_conn->close;
            }elsif($msg eq "undef") {
                undef $conn;
                $cv_finish->end;
            }
        });
        $conn->on(finish => sub {
            note("server finish 1");
            push(@finish_tokens, 1);
            undef $conn;
        });
        $conn->on(finish => sub {
            push(@finish_tokens, 2);
            undef $conn;
        });
        $conn->on(close => sub {
            push(@finish_tokens, 3);
            $cv_finish->end;
        });
    });
    ($port, my $guard) = run_server($server_runner, $app->to_app);

    _test_case "normal close from server", ["1:quit", "2:quit"], [1,2,3], sub {
        my $conn = shift;
        $cv_finish->begin;
        $conn->send("quit");
        $conn->on(finish => sub {
            note("client finish");
            undef $conn;
            $cv_finish->end;
        });
    };

    _test_case "delete server conn", ["1:undef", "2:undef"], [], sub {
        my $conn = shift;
        $cv_finish->begin;
        $conn->send("undef");
        $conn->on(finish => sub { undef $conn; $cv_finish->end });
    };

    _test_case "normal close from client", ["1:hoge", "2:hoge"], [1,2,3], sub {
        my $conn = shift;
        $cv_finish->begin;
        $conn->send("hoge");
        $conn->on(next_message => sub {
            my ($conn, $message) = @_;
            is($message->body, "hoge", "client received message OK");
            $conn->close();
        });
        $conn->on(finish => sub { undef $conn; $cv_finish->end });
    };

    _test_case "delete client conn", ["1:foobar", "2:foobar"], [1,2,3], sub {
        my $conn = shift;
        $cv_finish->begin;
        $conn->send("foobar");
        $conn->on(next_message => sub {
            my ($inner_conn, $message) = @_;
            is($message->body, "foobar", "client received message OK");
            undef $conn;
            $cv_finish->end;
        });
    };
}

1;
