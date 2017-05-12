#!/usr/bin/perl

use Mojo::Base -strict;

use Test::More tests => 2;

use Socket;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' ; }

use Mojo::IOLoop;
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
	fail('should not get here');
	Mojo::IOLoop->stop;
});

Mojo::IOLoop->singleton->reactor->catch(sub {
	my ($stream2, $err) = @_;
	like($err, qr|^I/O watcher failed: no trailing , in chunk|, 'expected error');
	Mojo::IOLoop->stop;
});

syswrite $sok2,'6:foobar!';

say 'start...';
Mojo::IOLoop->start;
say 'stop....';

