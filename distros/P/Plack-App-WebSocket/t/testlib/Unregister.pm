package testlib::Unregister;
use strict;
use warnings;
use Test::More;
use testlib::Util qw(set_timeout run_server);
use AnyEvent::WebSocket::Client;
use AnyEvent;

sub make_connection {
    my ($server_runner, $app) = @_;
    my ($port, $guard) = run_server($server_runner, $app);
    my $client = AnyEvent::WebSocket::Client->new;
    my $conn = $client->connect("ws://127.0.0.1:$port/")->recv;
    return ($conn, $guard);
}

sub run_tests {
    my ($server_runner) = @_;
    set_timeout;
    {
        note("-- on method returns unregister coderef. it is ok to call unregister more than once.");
        my $app = Plack::App::WebSocket->new(
            on_establish => sub {
                my ($conn) = @_;
                my $unregister = $conn->on(message => sub {
                    my ($conn, $msg) = @_;
                    $conn->send("1: still registered: $msg");
                });
                $conn->on(message => sub {
                    my ($conn, $msg) = @_;
                    if($msg eq "unregister") {
                        $unregister->();
                        $conn->send("2: do unregister");
                    }else {
                        $conn->send("2: do nothing: $msg");
                    }
                });
                $conn->on(finish => sub {
                    undef $conn;
                });
            }
        );
        my ($conn, $guard) = make_connection($server_runner, $app);
        my @got;
        my $finish_cv = AnyEvent->condvar;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            push @got, $msg->body;
        });
        $conn->on(finish => sub { $finish_cv->send });
        $conn->send("hoge");
        $conn->send("unregister");
        $conn->send("hoge");
        $conn->send("unregister");
        $conn->close;
        $finish_cv->recv;
        is_deeply \@got, [
            "1: still registered: hoge", "2: do nothing: hoge",
            "1: still registered: unregister", "2: do unregister",
            "2: do nothing: hoge",
            "2: do unregister"
        ];
    }
    {
        note("-- message event gets unregister coderef");
        my $app = Plack::App::WebSocket->new(
            on_establish => sub {
                my ($conn) = @_;
                foreach my $i (1 .. 5) {
                    $conn->on(message => sub {
                        my ($conn, $msg, $unreg) = @_;
                        if($msg == $i) {
                            $unreg->();
                            $conn->send("$i, $msg: unreg");
                        }else {
                            $conn->send("$i, $msg: pass");
                        }
                    });
                }
                $conn->on(finish => sub {
                    undef $conn;
                });
            }
        );
        my ($conn, $guard) = make_connection($server_runner, $app);
        my @got;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            push @got, $msg->body;
        });
        my $finish_cv = AnyEvent->condvar;
        $conn->on(finish => sub { $finish_cv->send });
        $conn->send($_) foreach (2, 4, 1, 3, 5);
        $conn->close;
        $finish_cv->recv;
        is_deeply \@got, [
            "1, 2: pass",
            "2, 2: unreg",
            "3, 2: pass",
            "4, 2: pass",
            "5, 2: pass",
            "1, 4: pass",
            "3, 4: pass",
            "4, 4: unreg",
            "5, 4: pass",
            "1, 1: unreg",
            "3, 1: pass",
            "5, 1: pass",
            "3, 3: unreg",
            "5, 3: pass",
            "5, 5: unreg"
        ];
    }
    {
        note("-- on method returns list of unregister coderefs, in the same order as the args");
        note("-- The unregister coderefs can be called in any order.");
        my $app = Plack::App::WebSocket->new(
            on_establish => sub {
                my ($conn) = @_;
                my @unregs;
                @unregs = $conn->on(
                    map {
                        my $i = $_;
                        message => sub {
                            my ($conn, $msg) = @_;
                            $unregs[$msg]->();
                            $conn->send("$i, $msg");
                        }
                    } (0 .. 4)
                );
                $conn->on(finish => sub { undef $conn });
            }
        );
        my ($conn, $guard) = make_connection($server_runner, $app);
        my @got;
        $conn->on(each_message => sub {
            my ($c, $msg) = @_;
            push @got, $msg->body;
        });
        my $finish_cv = AnyEvent->condvar;
        $conn->on(finish => sub { $finish_cv->send });
        $conn->send($_) foreach (3, 4, 0, 2, 1);
        $conn->close;
        $finish_cv->recv;
        is_deeply \@got, [
            "0, 3",
            "1, 3",
            "2, 3",
            "3, 3",
            "4, 3",
            "0, 4",
            "1, 4",
            "2, 4",
            "4, 4",
            "0, 0",
            "1, 0",
            "2, 0",
            "1, 2",
            "2, 2",
            "1, 1"
        ];
    }
}

1;
