#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use LWP::UserAgent;
use HTTP::Request;
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
    http_local_addr       => '127.0.0.1',
    http_local_port       => $port,
    http_startup_timeout  => 10,
    http_activity_timeout => 10,
    http_mirrors          => {},
    http_result           => '/result.xml',
);

ok( 1, 'Server created' ); # 2

$server->prepare() or die $server->{errstr};

ok( 1, 'Server prepared' ); # 3

$server->run();

ok( !$server->{exitcode}, 'Server ran and timed out' ); # 4

ok( $server->http_result( '/result.xml' ) eq 'Blah Blah Blah Blah Blah', 'Got result.xml' );

exit(0);

sub _lwp {
  my $port = shift || return;
  my $ua = LWP::UserAgent->new;
  $ua->timeout(10);
  my $response = $ua->get("http://127.0.0.1:$port/");
  die unless $response->is_success;
  sleep 5;
  #my $content = $ua->get("http://127.0.0.1:$port/cpan/Makefile.PL");
  #die unless $content->is_success;
  my $request = HTTP::Request->new( PUT => "http://127.0.0.1:$port/result.xml" );
  $request->content("Blah Blah Blah Blah Blah");
  $ua->request( $request );
  sleep 5;
  return;
}
