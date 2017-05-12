use strict;
use warnings;

use FindBin qw( $Bin );
use Test::More;
use Test::TCP;
use File::Temp ();
use Perlbal::Test ();

## make sure commands are available
for my $cmd (qw( start_server perlbal )) {
    chomp(my $bin = `which $cmd`);
    plan skip_all => "$cmd not found in PATH"
        unless $bin && -x $bin;
}

test_tcp(
    server => sub {
        my $port = shift;

        my $conf_fh = File::Temp->new;
        print $conf_fh <<"CONF";
LOAD ServerStarter
LOAD Vhosts

CREATE SERVICE frontend
  SET role    = selector
  SET plugins = Vhosts
  LISTEN = $port
  VHOST * = web
ENABLE frontend

CREATE SERVICE web
  SET role    = web_server
  SET docroot = $Bin/htdocs
ENABLE web
CONF
        exec 'start_server', '--port', $port, '--interval', '3',
             '--', 'perlbal', '-c', $conf_fh->filename;
    },
    client => sub {
        my ($port, $pid) = @_;

        my $ua  = Perlbal::Test::ua();
        my $res = $ua->get("http://localhost:$port/");
        ok $res;
        ok $res->is_success;
        like $res->content, qr{this is index};

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
