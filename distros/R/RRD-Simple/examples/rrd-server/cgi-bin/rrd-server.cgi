#!/usr/bin/perl -w
############################################################
#
#   $Id: rrd-server.cgi 693 2006-06-26 19:11:42Z nicolaw $
#   rrd-server.cgi - Data gathering CGI script for RRD::Simple
#
#   Copyright 2006, 2007 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################
# vim:ts=4:sw=4:tw=78

# User defined constants
use constant BASEDIR => '/home/nicolaw/webroot/www/rrd.me.uk';

############################################################




use 5.6.1;
use warnings;
use strict;
use Socket;

# We'll need to print a header unless we're in MOD_PERL land
print "Content-type: plain/text\n\n" unless exists $ENV{MOD_PERL};

my $host;
my $param = get_query($ENV{QUERY_STRING});
my $remote_addr = $ENV{REMOTE_ADDR};

# Take the host from the "target" if they know the "secret"
if (defined($ENV{RRD_SECRET}) && defined($param->{secret} && defined($param->{target}))
		&& "$ENV{RRD_SECRET}" eq "$param->{secret}") {
	$host = $param->{target};

} else {
	# Check for HTTP proxy source addresses
	for (qw(HTTP_X_FORWARDED_FOR HTTP_VIA HTTP_CLIENT_IP HTTP_PROXY_CONNECTION
			FORWARDED_FOR X_FORWARDED_FOR X_HTTP_FORWARDED_FOR HTTP_FORWARDED)) {
		if (defined $ENV{$_} && $ENV{$_} =~ /([\d\.]+)/) {
			my $ip = $1;
			if (isIP($ip)) {
				$remote_addr = $ip;
				last;
			}
		}
	}

	# Fail if we can't see who is sending us this data
	unless ($remote_addr) {
		print "FAILED - NO REMOTE_ADDR\n";
		exit;
	}

	$host = ip2host($remote_addr);
	my $ip = host2ip($host);

	# Fail if we don't believe they are who their DNS says they are
	if ("$ip" ne "$remote_addr") {
		print "FAILED - FORWARD AND REVERSE DNS DO NOT MATCH\n";
		exit;
	}

	# Custom hostname flanges
	$host = 'legolas.wd.tfb.net'    if $host eq 'bb-87-80-233-47.ukonline.co.uk' || $ip eq '87.80.233.47';
	$host = 'pippin.wd.tfb.net'     if $host eq '82.153.185.41' || $ip eq '82.153.185.41';
	$host = 'pippin.wd.tfb.net'     if $host eq '82.153.185.40' || $ip eq '82.153.185.40';
	$host = 'isle-of-cats.etla.org' if $ip   eq '82.71.23.88';
}

# Build a list of valid pairs
my @pairs;
while (<>) {
	#warn "$host $_";
	next unless /^\d+\.[\w\.\-\_\d]+\s+[\d\.]+\s*$/;
	push @pairs, $_;
}

# Don't bother opening a pipe if there's nothing to sent
unless (@pairs) {
	printf("OKAY - %s - no valid pairs\n", $host);

} else {
	# Simply open a handle to the rrd-server.pl and send in the data
	if (open(PH,'|-', BASEDIR."/bin/rrd-server.pl -u $host")) {
		print PH $_ for @pairs;
		close(PH);
		printf("OKAY - %s - received %d pairs\n", $host, scalar(@pairs));

	# Say if we failed the customer :)
	} else {
		print "FAILED - UNABLE TO EXECUTE\n";
	}
}

exit;

sub get_query {
	my $str = shift;
	my $kv = {};
	$str =~ tr/&;/&/s;
	$str =~ s/^[&;]+//, $str =~ s/[&;]+$//;
	for (split /[&;]/, $str) {
		my ($k,$v) = split(/=/, $_, 2);
		next if $k eq '';
		$kv->{url_decode($k)} = url_decode($v);
	}
	return $kv;
} 

sub url_decode {
	local $_ = @_ ? shift : $_;
	defined or return;
	tr/+/ /;
	s/%([a-fA-F0-9]{2})/pack "H2", $1/eg;
	return $_;
} 

sub ip2host {
	my $ip = shift;
	my @numbers = split(/\./, $ip);
	my $ip_number = pack("C4", @numbers);
	my ($host) = (gethostbyaddr($ip_number, 2))[0];
	if (defined $host && $host) {
		return $host;
	} else {
		return $ip;
	}
}

sub isIP {
	return 0 unless defined $_[0];
	return 1 if $_[0] =~ /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.
				(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.
				(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.
				(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/x;
	return 0;
}

sub resolve {
	return ip2host(@_) if isIP($_[0]);
	return host2ip(@_);
}

sub host2ip {
	my $host = shift;
	my @addresses = gethostbyname($host);
	if (@addresses > 0) {
		@addresses = map { inet_ntoa($_) } @addresses[4 .. $#addresses];
		return wantarray ? @addresses : $addresses[0];
	} else {
		return $host;
	}
}

1;

