use strict;
use warnings;
use feature 'say';

use Test::More tests => 7;

BAIL_OUT "No support for OS" if $^O eq "MSWin32";

use File::Temp 'tempdir';
use IO::Socket::UNIX;

use Mojo::UserAgent::UnixSocket;

Test::More->builder->no_ending(1);
Test::More->builder->use_numbers(0);

my $ua = Mojo::UserAgent::UnixSocket->new;
$ua->inactivity_timeout(3);
my $dir = tempdir CLEANUP => 1;

my $socket_path = "$dir/foobar.sock";
unlink $socket_path if -e $socket_path;

my $socket = IO::Socket::UNIX->new(
    Local   => $socket_path,
    Type    => SOCK_STREAM,
    Listen => 1
);
die "No socket! $!" unless $socket;

# fire up a server
my $pid = fork();
if ($pid == 0) {
    while (1) {
        next unless my $connection = $socket->accept;
        $connection->autoflush(1);
        while (my $line = <$connection>) {
            chomp($line);
            like $line, qr$GET /greetings\?enthusiastic=1 HTTP/1.1$, "server sees right request" if $line =~ /^GET/;
            like $line, qr/localhost/i, "server sees right host" if $line =~ /Host:/;
            if ($line =~ /^\R$/) {
                my $res = "<!DOCTYPE HTML><html><body><h1>Good morning to you!</h1></body></html>";

                say $connection "HTTP/1.1 200 OK";
                say $connection "Content-Type: text/html; charset=UTF-8";
                say $connection "Content-Length: " . length $res;
                say $connection '';
                say $connection $res;
                close $connection and last;
            }
        }
        last;
    }
    exit 0;
}

my $tx = $ua->get("unix://$socket_path/greetings?enthusiastic=1");
waitpid($pid, 0);

my $url = $tx->req->url;
ok $url->scheme eq 'unix', "UA has right url scheme";
ok $url->path eq '/greetings', "UA has right url path";
ok $url->query eq 'enthusiastic=1', "UA has right url query";
ok $url->host eq 'localhost', "UA has right host header";

my $res = $tx->res;
like $res->dom->at('h1')->text, qr/Good morning to you!/, "UA got right server response";
