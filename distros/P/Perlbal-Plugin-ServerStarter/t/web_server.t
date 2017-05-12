use strict;
use warnings;

use FindBin qw( $Bin );
use Test::More;
use Test::TCP;
use File::Temp ();
use Perlbal::Test ();
use IO::Socket;

## make sure commands are available
for my $cmd (qw( start_server perlbal )) {
    chomp(my $bin = `which $cmd`);
    plan skip_all => "$cmd not found in PATH"
        unless $bin && -x $bin;
}

my $mgmt_port = '127.0.0.1:' . Perlbal::Test::new_port();

test_tcp(
    server => sub {
        my $port = shift;

        my $conf_fh = File::Temp->new;
        print $conf_fh <<"CONF";
LOAD ServerStarter

CREATE SERVICE web
  SET role    = web_server
  SET docroot = $Bin/htdocs
  LISTEN = $port
ENABLE web

CREATE SERVICE mgmt
  SET role = management
  LISTEN = $mgmt_port
ENABLE mgmt
CONF
        exec 'start_server', '--port', $port, '--port', $mgmt_port, '--interval', '3',
             '--', 'perlbal', '-c', $conf_fh->filename;
    },
    client => sub {
        my ($port, $pid) = @_;

        my $ua = Perlbal::Test::ua();
        my $res;
        
        ## simple GET request test
        $res = $ua->get("http://localhost:$port/");
        ok $res;
        ok $res->is_success;
        like $res->content, qr{this is index};

        ## test to connect management role 
        my $mgmt_sock = IO::Socket::INET->new(
            PeerAddr  => $mgmt_port,
            Proto     => 'tcp',
            Timeout   => 2,
        );
        ok $mgmt_sock, 'connect mgmt_port';
        is $mgmt_sock->syswrite("dumpconfig\n"), 11, 'send dumpconfig';
        ok $mgmt_sock->sysread(my $buf, 1024*4), 'receive dumpconfig result';
        like $buf, qr{\bcreate service web\b}im;

        ## restart with sending HUP to start_server
        kill 'HUP', $pid;
        sleep 5;

        ## simple GET again
        $res = $ua->get("http://localhost:$port/");
        ok $res;
        ok $res->is_success;
        like $res->content, qr{this is index};
    },
);

done_testing;
