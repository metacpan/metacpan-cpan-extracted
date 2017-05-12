#!/usr/bin/perl

use Mojo::Base -strict;

use Test::More tests => 3;

use Socket;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' ; }

use Mojo::IOLoop;
use Mojo::IOLoop::Stream;

use MojoX::LineStream;

socketpair(my $sok1, my $sok2, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";

my $stream = Mojo::IOLoop::Stream->new($sok1);
$stream->start();

my $ls = MojoX::LineStream->new(stream => $stream);

isa_ok($ls, 'MojoX::LineStream');

$ls->on(line => sub {
	my ($ls2, $line) = @_;
	is($line, 'foobar', 'got foobar');
	$ls2->writeln('bar2foo');	
	Mojo::IOLoop->stop;
});

syswrite $sok2, "foobar\n";

say 'start...';
Mojo::IOLoop->start;
say 'stop....';

sysread $sok2, my $resp, 100;

is($resp, "bar2foo\n", 'got bar2foo');

