use strict;
use warnings;
use Test::More;
use AnyEvent;
use Plack::App::WebSocket;
use FindBin;
use lib ("$FindBin::RealBin/../t");
use testlib::Util qw(set_timeout);
use Test::Requires {
    "Twiggy::Server" => "0"
};
use Twiggy::Server;

if(!$ENV{ANYEVENT_WEBSOCKET_SERVER_BROWSER_TEST}) {
    plan skip_all => "Set environment variable ANYEVENT_WEBSOCKET_SERVER_BROWSER_TEST=1 to run the browser test.";
}

my $TIMEOUT = 30;

set_timeout($TIMEOUT);

my $cv_finish = AnyEvent->condvar;

my $ws_app = Plack::App::WebSocket->new(
    on_establish => sub {
        my ($conn) = @_;
        $conn->on(message => sub {
            my ($inner_conn, $msg) = @_;
            note("Received message: size " . length($msg));
            if($msg eq "QUIT") {
                $inner_conn->close;
            }elsif($msg eq "UNDEF") {
                undef $conn;
            }elsif($msg eq "DONE_TESTING") {
                note("DONE_TESTING received");
                $inner_conn->close;
                $cv_finish->send;
            }else {
                $inner_conn->send($msg);
            }
        });
        $conn->on(finish => sub {
            note("Connection closed");
            undef $conn;
        });
        $conn->send("connected");
    }
);

my $server = Twiggy::Server->new(
    host => "127.0.0.1", port => 18888
);
$server->register_service($ws_app->to_app);

diag("Now connect to file://$FindBin::RealBin/js/browser.html within $TIMEOUT seconds!");
$cv_finish->recv;

pass "test run through";
done_testing;

