#!/usr/bin/perl

use utf8;
use Encode qw(decode_utf8 encode_utf8);

use Mojo::Base -strict;

use Test::More tests => 3;

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

my $string1 = 'ƒòōƃăŗ';
my $string2 = 'ƃăŗ2ƒòō';

$ns->on(chunk => sub {
	use bytes;
	my ($ns2, $chunk) = @_;
	say "$chunk ne $string1" if $chunk ne $string1;
	ok($chunk eq $string1, "got $string1");
	$ns2->write($string2);
	Mojo::IOLoop->stop;
});

{
	use bytes;
	#syswrite $sok2,'6:ƒòōƃăŗ,';
	syswrite $sok2, length($string1) . ':' . $string1 . ',';
}

say 'start...';
Mojo::IOLoop->start;
say 'stop....';

{
	use bytes;
	sysread $sok2, my $resp, 100;

	my $want = length($string2) . ':' . $string2 . ',';
	say 'resp: ', $resp;
	say 'want: ', $want;

	ok($resp eq $want, "got $resp");
}


