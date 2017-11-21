#!/usr/bin/perl

use Mojo::Base -strict;

use Test::More tests => 3;

use Socket;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' ; }

use Mojo::IOLoop;
use Mojo::IOLoop::Stream;

use MojoX::NetstringStream;

socketpair(my $sok1, my $sok2, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";

my $stream1 = Mojo::IOLoop::Stream->new($sok1);
$stream1->start();

my $ns1 = MojoX::NetstringStream->new(stream => $stream1);

isa_ok($ns1, 'MojoX::NetstringStream');

$ns1->on(chunk => sub {
	my ($ns2, $chunk) = @_;
	fail('should not get here');
	Mojo::IOLoop->stop;
});

$ns1->on(nserr => sub {
	my ($ns2, $err) = @_;
	like($err, qr|^no trailing , in chunk|, 'expected error no trailing ,');
	Mojo::IOLoop->stop;
});

syswrite $sok2,'6:foobar!';

say 'start...';
Mojo::IOLoop->start;
say 'stop....';

socketpair(my $sok3, my $sok4, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";

my $stream2 = Mojo::IOLoop::Stream->new($sok3);
$stream2->start();

my $ns3 = MojoX::NetstringStream->new(stream => $stream2, maxsize => 10);

$ns3->on(chunk => sub {
	my ($ns2, $chunk) = @_;
	fail('should not get here');
	Mojo::IOLoop->stop;
});

$ns3->on(nserr => sub {
	my ($ns2, $err) = @_;
	like($err, qr|^netstring too big:|, 'expected error too big');
	Mojo::IOLoop->stop;
});

syswrite $sok4,'12:foobarfoobar!';

say 'start...';
Mojo::IOLoop->start;
say 'stop....';
