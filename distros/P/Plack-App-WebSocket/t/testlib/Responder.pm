package testlib::Responder;
use strict;
use warnings;
use Test::More;
use Plack::App::WebSocket;
use AnyEvent;
use AnyEvent::WebSocket::Client;
use testlib::Util qw(set_timeout run_server);
use Plack::Util ();
use Scalar::Util qw(weaken);

my @client_messages = ();
my @responses = ();
my $cv_response;
my $port;

sub _test_case {
    my ($label, $exp_client_messages, $code) = @_;
    @responses = ();
    @client_messages = ();
    $cv_response = AnyEvent->condvar;
    my $client_conn = AnyEvent::WebSocket::Client->new->connect("ws://127.0.0.1:$port/")->recv;
    $client_conn->on(each_message => sub {
        fail("Unexpected message received from server: " . $_[1]->body);
    });
    $code->($client_conn);
    undef $client_conn;
    $cv_response->recv;
    is_deeply(\@client_messages, $exp_client_messages, "$label: client messages OK");
    is(scalar(@responses), 1, "$label: 1 PSGI response OK");
    is($responses[0][0], 200, "$label: ... and its status is 200");
    is($responses[0][2][0], "WebSocket finished", "... and its content OK");
}

sub run_tests {
    my ($server_runner) = @_;
    note("When a Plack::App::WebSocket::Connection object is destroyed, the corresponding responder must be called.");
    note("This is because a responder keeps some kind of session information used by its PSGI server.");
    note("That session information must be released by calling the responder when the WebSocket connection is finished.");

    set_timeout;
    local $Plack::App::WebSocket::Connection::WAIT_FOR_FLUSHING_SEC = 0.1; ## hidden config
    
    my $ws_app = Plack::App::WebSocket->new(on_establish => sub {
        my ($conn) = @_;
        $conn->on(message => sub {
            my ($inner_conn, $data) = @_;
            push(@client_messages, $data);
            if($data eq "quit") {
                $inner_conn->close;
            }elsif($data eq "undef") {
                undef $conn;
            }
        });
        $conn->on(finish => sub { undef $conn });
    });
    ($port, my $guard) = run_server($server_runner, sub {
        my ($env) = @_;
        return Plack::Util::response_cb($ws_app->call($env), sub {
            my ($res) = @_;
            push(@responses, $res);
            $cv_response->send;
        });
    });

    _test_case "normal close from server", ["quit"], sub {
        my $conn = shift;
        $conn->send("quit");
        $conn->on(finish => sub { undef $conn });
    };
    _test_case "delete server conn", ["undef"], sub {
        my $conn = shift;
        $conn->send("undef");
        $conn->on(finish => sub { undef $conn });
    };
    _test_case "normal close from client", ["foo", "bar"], sub {
        my $conn = shift;
        $conn->send("foo");
        $conn->send("bar");
        $conn->close();
        $conn->on(finish => sub { undef $conn });
    };
    _test_case "delete client conn", [], sub { };
}

1;
