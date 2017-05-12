#!/usr/bin/perl

use Mojo::Base -strict;

use Test::More tests => 3;

use Socket;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' ; }

use Mojo::IOLoop;
#use Mojo::IOLoop::Client;
#use Mojo::IOLoop::Delay;
#use Mojo::IOLoop::Server;
use Mojo::IOLoop::Stream;

use MojoX::NetstringStream;

socketpair(my $sok1, my $sok2, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";

my $stream = Mojo::IOLoop::Stream->new($sok1);
$stream->start();

my $ns = MojoX::NetstringStream->new(stream => $stream);

isa_ok($ns, 'MojoX::NetstringStream');

$ns->on(chunk => sub {
	my ($ns2, $chunk) = @_;
	is($chunk, 'foobar', 'got foobar');
	$ns2->write('bar2foo');	
	Mojo::IOLoop->stop;
});

syswrite $sok2,'6:foobar,';

say 'start...';
Mojo::IOLoop->start;
say 'stop....';

sysread $sok2, my $resp, 100;

is($resp, '7:bar2foo,', 'got 7:bar2foo');

