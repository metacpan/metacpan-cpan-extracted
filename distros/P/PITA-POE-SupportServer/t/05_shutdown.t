#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use LWP::UserAgent;
use IO::Socket::INET;

BEGIN {
	use_ok( 'PITA::POE::SupportServer' ); # 1
};

my $port;

{
  my $listen = IO::Socket::INET->new(
		Listen    => 5,
		LocalAddr => '127.0.0.1',
		Proto     => 'tcp',
		Reuse     => 1,
  ) or die "$! creating socket\n";

  $port = $listen->sockport();

}

my $server = PITA::POE::SupportServer->new(
    execute => [
        \&_lwp, $port,
    ],
    http_local_addr => '127.0.0.1',
    http_local_port => $port,
    http_startup_timeout => 10,
    http_activity_timeout => 10,
    http_shutdown_timeout => 10,
    http_mirrors => { '/cpan', '.' },
);

ok( 1, 'Server created' ); # 2

$server->prepare() or die $server->{errstr};

ok( 1, 'Server prepared' ); # 3

$server->run();

ok( $server->{exitcode}, 'Server ran and timed out' ); # 4

exit(0);

sub _lwp {
  local $SIG{TERM} = sub { sleep 60; };
  my $port = shift || return;
  my $ua = LWP::UserAgent->new;
  $ua->timeout(10);
  my $response = $ua->get("http://127.0.0.1:$port/");
  die unless $response->is_success;
  sleep 60;
  return;
}
