#!/usr/bin/perl -w

#
# I've been told at times that this or that sort function is
# faster for sorting IP addresses.  I've decied that I won't
# accept undocumented claims anymore.
#
# This file provides a way to test out sort functions.  If you 
# think you've got a faster one, please try re-defining &mysortfunc.
# If it's faster, let me know.  If it's not, don't.
#

sub mysortfunc
{
	return sort { pack("C4",split(/\./,$a)) cmp pack("C4",split(/\./,$b)) } @_
}

BEGIN {
	unless (-t STDOUT) {
		print "1..0 # Skipped: this is for people looking for faster sorts\n";
		exit(0);
	}
}

use Net::Netmask;
use Net::Netmask qw(sameblock cmpblocks);
use Carp;
use Carp qw(verbose);

use Benchmark qw(cmpthese);


sub generate {
	my $count = shift || 10000;
	my @list;
	$list[$count-1]='';  ## preallocate
	for (my $i=0; $i<$count; $i++) {
		my $class = int(rand(3));
		if ($class == 0) {
			## class A ( 1.0.0.0 - 126.255.255.255 )
			$list[$i] = int(rand(126))+1;
		} elsif ($class == 1) {
			## class B ( 128.0.0.0 - 191.255.255.255 )
			$list[$i] = int(rand(64))+128;
		} else {
			## class C ( 192.0.0.0 - 223.255.255.255 )
			$list[$i] = int(rand(32))+192;
		}
		$list[$i] .= '.' . int(rand(256));
		$list[$i] .= '.' . int(rand(256));
		$list[$i] .= '.' . int(rand(256));
	}
	return @list;
}

my (@iplist) = generate(500);


cmpthese (-1, {
	candidate => sub {
		my (@x) = mysortfunc(@iplist);
	},
	distributed => sub {
		my (@x) = sort_by_ip_address(@iplist);
	},
});


