#!/usr/bin/perl -w
############################################################
#
#   $Id$
#   rrd-client-nagios-perfdata.pl - Send Nagios performance data to rrd-server.cgi
#
#   Copyright 2007, 2008 Nicola Worthington
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

use 5.6.1;
use strict;
use warnings;
no warnings qw(redefine);
use Getopt::Std qw();
use vars qw($VERSION);

$VERSION = '1.42' || sprintf('%d', q$Revision: 775 $ =~ /(\d+)/g);
$ENV{PATH} = '/bin:/usr/bin';
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# Get command line options
my %opt = ();
$Getopt::Std::STANDARD_HELP_VERSION = 1;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
Getopt::Std::getopts('l:e:T:H:A:s:o:e:p:vh',\%opt);
(HELP_MESSAGE() && exit) if defined $opt{h} || defined $opt{'?'};
(VERSION_MESSAGE() && exit) if defined $opt{v};
(HELP_MESSAGE() && exit) unless defined $opt{l} && defined $opt{e} && defined $opt{s} && defined $opt{p};

my $time = $opt{T}; $time ||= time;
(my $svc = $opt{s}) =~ s/[^a-zA-Z_0-9]//g;
my $type = 'service';

# Build the data
my $post;
$post .= sprintf("%d.nagios.perfdata.%s.%s.latency %f\n", $time, $type, lc($svc), $opt{l});
$post .= sprintf("%d.nagios.perfdata.%s.%s.execution %f\n", $time, $type, lc($svc), $opt{e});
        
# HTTP POST the data if asked to
print scalar(basic_http('POST',$opt{p},10,$post,$opt{q}))."\n" if $opt{p};

exit;


# Display help
sub HELP_MESSAGE {
        print qq{Syntax: rrd-client-nagios-perfdata.pl [OPTIONS]
   -l %SERVICELATENCY%
   -e 
   -s 
   -c 
   -p <URL>        HTTP POST data to the specified URL
   -q              Suppress all warning messages
   -v              Display version information
   -h              Display this help
\n};
}

# Display version
sub VERSION { &VERSION_MESSAGE; }
sub VERSION_MESSAGE {
	print "$0 version $VERSION ".'($Id: rrd-client-nagios-perfdata.pl 775 2006-10-08 18:47:33Z nicolaw $)'."\n";
}

# Basic HTTP client if LWP is unavailable
sub basic_http {
	my ($method,$url,$timeout,$data,$quiet) = @_;
	$method ||= 'GET';
	$url ||= 'http://localhost/';
	$timeout ||= 5;

	my ($scheme,$host,$port,$path) = $url =~ m,^(https?://)([\w\d\.\-]+)(?::(\d+))?(.*),i;
	$scheme ||= 'http://';
	$host ||= 'localhost';
	$path ||= '/';
	$port ||= 80;
	
	my $str = '';
	eval "use Socket";
	return $str if $@;

	eval {
		local $SIG{ALRM} = sub { die "TIMEOUT\n" };
		alarm $timeout;

		my $iaddr = inet_aton($host) || die;
		my $paddr = sockaddr_in($port, $iaddr);
		my $proto = getprotobyname('tcp');
		socket(SOCK, AF_INET(), SOCK_STREAM(), $proto) || die "socket: $!";
		connect(SOCK, $paddr) || die "connect: $!";

		select(SOCK); $| = 1;
		select(STDOUT);

		# Send the HTTP request
		print SOCK "$method $path HTTP/1.1\n";
		print SOCK "Host: $host". ("$port" ne "80" ? ":$port" : '') ."\n";
		print SOCK "User-Agent: $0 version $VERSION ".'($Id: rrd-client-nagios-perfdata.pl 775 2006-10-08 18:47:33Z nicolaw $)'."\n";
		if ($data && $method eq 'POST') {
			print SOCK "Content-Length: ". length($data) ."\n";
			print SOCK "Content-Type: application/x-www-form-urlencoded\n";
		}
		print SOCK "\n";
		print SOCK $data if $data && $method eq 'POST';

		my $body = 0;
		while (local $_ = <SOCK>) {
			s/[\n\n]+//g;
			$str .= $_ if $_ && $body;
			$body = 1 if /^\s*$/;
		}
		close(SOCK);
		alarm 0;
	};

	warn "Warning [basic_http]: $@" if !$quiet && $@ && $data;
	return wantarray ? split(/\n/,$str) : "$str";
}

1;

