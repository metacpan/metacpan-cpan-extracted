#!/usr/bin/env perl
use strict;
use warnings;
use IO::Async::Loop;
use Net::Async::HTTP;
use Net::Async::HTTP::DAV;
use POSIX qw(strftime);

my $loop = IO::Async::Loop->new;
my $uri = URI->new(shift @ARGV) or die 'please provide a URI';
$loop->add(my $dav = Net::Async::HTTP::DAV->new(
	host => $uri->host,
));
$dav->propfind(
	path => $uri->path,
	on_item => sub {
		my ($item) = @_;
		printf "%-32.32s %-64.64s %12d\n",
			strftime("%Y-%m-%d %H:%M:%S", localtime $item->{modified}),
			$item->{displayname},
			$item->{size} // 0;
	},
)->get
