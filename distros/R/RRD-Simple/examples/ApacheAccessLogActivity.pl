#!/usr/bin/perl -w
############################################################
#
#   $Id: ApacheAccessLogActivity.pl 965 2007-03-01 19:11:23Z nicolaw $
#   ApacheAccessLogActivity.pl - Example script bundled as part of RRD::Simple
#
#   Copyright 2005,2006 Nicola Worthington
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

use strict;
use integer;

use Getopt::Std qw();
use Time::Local qw(timelocal);
use RRD::Simple qw(:all);

$RRD::Simple::DEFAULT_DSTYPE = 'GAUGE';

my $opt = {};
Getopt::Std::getopts('hvo:r:f:', $opt);
help() if exists $opt->{h};
version() if exists $opt->{v};

$opt->{o} ||= '.';
$opt->{r} ||= 'apache.rrd';
$opt->{f} ||= -f '/usr/local/apache/logs/access_log' ?
				'/usr/local/apache/logs/access_log' :
				'/var/log/httpd/access_log';

my %graphs = (
		responses => [ qw(200 300 400 500) ],
		requests => [ qw(TotalReq UniqIP) ],
		filetypes => [ qw(Images HtmlPages OtherFiles) ],
	);

my @ds = (@{$graphs{responses}},@{$graphs{requests}},@{$graphs{filetypes}});
my %data = ( map { $_ => {} } @ds );

my $fh;
if (!key_ready() && -f $opt->{f}) {
	require IO::File;
	$fh = IO::File->new("<$opt->{f}") ||
		die "Unable to open file handle for file '$opt->{f}': $!";
} else {
	require IO::Handle;
	$fh = new IO::Handle;
	$fh->fdopen(fileno(STDIN),'r');
}

my ($first,$processed) = (0,0);
my $last = eval { last_update($opt->{r}) } || 0;

seek($fh,-2048,2); <$fh>;
my $last_bucket = (timestamp2unixtime(<$fh>) / 300) * 300;
seek($fh,0,0);

while (<$fh>) {
	my $time = timestamp2unixtime($_);
	next unless defined($time);

	my $bucket = ( $time / 300 ) * 300;
	next unless $bucket > $last;
	$first ||= $bucket;

	$data{TotalReq}->{$bucket}++;
	my ($ext,$resp) = $_ =~ /(?:\.(\w+?)(?:[\&\?].*)?)? HTTP\/1\.." ([2345])\d\d /;
	$data{"${resp}00"}->{$bucket}++;
	$ext ||= '';
	if ($ext =~ /^jpe?g|png|tiff?|bmp|gif|img|pcx|pic$/i) {
		$data{"Images"}->{$bucket}++;
	} elsif ($ext =~ /^[jmps]?html?|jsp|stm|php[34]?|asp|bml|cgi|pl$/i) {
		$data{"HtmlPages"}->{$bucket}++;
	} else {
		$data{"OtherFiles"}->{$bucket}++;
	}

	$processed++;
	if (!($processed % 1000) || $bucket == $last_bucket) {
		print "$processed\n";
		for (my $t = $first; $t <= $bucket; $t += 300) {
			my @vals;
			for my $type (keys %data) {
				push @vals, ($type,(exists $data{$type}->{$t} ?
					$data{$type}->{$t} : 0));
			}
			eval { update($opt->{r},$t,@vals) };
		}
		$last = $bucket;
		$first = 0;
		%data = ( map { $_ => {} } @ds );
	}
}

for my $graph (keys %graphs) {
	graph($opt->{r},
			destination      => $opt->{o},
			basename         => $graph,
			sources          => [ @{$graphs{$graph}} ],
			width            => 600,
			title            => 'Apache Activity',
			'vertical-label' => 'Requests',
			'line-thickness' => 1,
		);
}

exit;

##############################################

sub version {
	print '$Id: ApacheAccessLogActivity.pl 965 2007-03-01 19:11:23Z nicolaw $'."\n";
	exit;
}

sub help {
	print <<EOH;
Syntax: $0 [-h|-v] [-f logfile] [-r rrd filename] [-o graph outputdir]
     -h              Display this help
     -v              Display version information
     -f <logfile>    Specify the input logfile (uses STDIN by default)
     -r <filename>   Path and filename or the RRD file to write to
     -o <directory>  Output directory where graphs should be created
EOH
	exit;
}

sub timestamp2unixtime {
	my %months = (qw(Jan 0 Feb 1 Mar 2 Arp 3 May 4 Jun 5
				Jul 6 Aug 7 Sep 8 Oct 9 Nov 10 Dec 11));
	if (my ($mday,$mon,$year,$hour,$min,$sec,$offset) =
		$_[0] =~ m# \[(..)/(...)/(....):(..):(..):(..) (.....)\] #) {
		my @val = split(/\s/,sprintf('%d %d %d %d %d %d',
				$sec,$min,$hour,$mday,$months{$mon},($year-1900)));
		return timelocal(@val);
	}
	return undef;
}

sub key_ready {
	my ($rin, $nfd) = ('','');
	vec($rin, fileno(STDIN), 1) = 1;
	return $nfd = select($rin,undef,undef,0);
}

__END__

