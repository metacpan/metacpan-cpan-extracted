#!perl -T

use strict;
use warnings;
use Test::More tests => 4;
use Sys::Sendfile;
use Fcntl 'SEEK_SET';
use IO::Socket::INET;

alarm 2;

my $bound = IO::Socket::INET->new(Listen => 1, ReuseAddr => 1, LocalAddr => 'localhost') or die "Couldn't make listening socket: $!";
my $in = IO::Socket::INET->new(PeerHost => $bound->sockhost, PeerPort => $bound->sockport) or die "Couldn't make input socket: $!";
my $out = $bound->accept;

my $slurped = do {
	open my $self, '<', $0 or die "Couldn't open self: $!";
	local $/;
	<$self>;
};

{
	open my $self, '<', $0 or die "Couldn't open self: $!";

	my $size = -s $self;
	is(sendfile($out, $self, $size), $size, "Wrote $size bytes when asked to send the whole file") or diag "Error message: $!";
	defined recv $in, my $read, -s $self, 0 or die "Couldn't receive: $!";

	is($read, $slurped, "Read the same as was written");
}

{
	open my $self, '<', $0 or die "Couldn't open self: $!";

	my $size = -s $self;
	is(sendfile($out, $self), $size, "Wrote $size bytes when asked to send the whole file") or diag "Error message: $!";
	defined recv $in, my $read, -s $self, 0 or die "Couldn't receive: $!";

	is($read, $slurped, "Read the same as was written");
}
