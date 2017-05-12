package testlib::Cycle;
use strict;
use warnings;
use Test::More;
use Plack::App::WebSocket;
use AnyEvent::WebSocket::Client;
use testlib::Util qw(set_timeout run_server);
use AnyEvent;
use Scalar::Util qw(weaken);

sub run_tests {
    my ($server_runner) = @_;
    set_timeout;
    my $server_conn;
    my @messages = ();
    my $cv_finish = AnyEvent->condvar;
    my $cv_establish = AnyEvent->condvar;
    my $app = Plack::App::WebSocket->new(on_establish => sub {
        my $conn = shift;
        if(defined($server_conn)) {
            fail("More than one connection. something is wrong.");
            return;
        }
        $cv_finish->begin;
        $server_conn = $conn;
        weaken $server_conn;
        $cv_establish->send;
        $conn->on(message => sub {
            my ($conn, $message) = @_;
            push(@messages, $message);
            if($message eq "quit") {
                $conn->close();
            }
        });
        $conn->on(finish => sub {
            undef $conn;
            $cv_finish->end;
        });
    });
    
    my ($port, $guard) = run_server($server_runner, $app->to_app);
    my $client = AnyEvent::WebSocket::Client->new;
    my $client_conn = $client->connect("ws://127.0.0.1:$port/")->recv;
    $cv_establish->recv;
    ok defined($server_conn), "server connection is alive because of the looping closure at finish callback";
    $cv_finish->begin;
    $client_conn->on(finish => sub { undef $client_conn; $cv_finish->end });
    $client_conn->send("hoge");
    $client_conn->send("quit");
    $cv_finish->recv;
    is_deeply \@messages, ["hoge", "quit"], "messages received by the server OK";
    ok !defined($server_conn), "server connection is destroyed because of the self-destruction in finish callback";
}

1;
