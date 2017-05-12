#!/usr/bin/perl -w
############################################################
#
#   $Id: mod_perl.pl 965 2007-03-01 19:11:23Z nicolaw $
#   mod_perl.pl - Example script bundled as part of RRD::Simple
#
#   Copyright 2006 Nicola Worthington
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

umask(0022);

use 5.8.3;
use strict;
use LWP::UserAgent;
use RRD::Simple "1.34";
use RRDs;
use File::Spec;
use Socket;
use File::Spec::Functions qw(catdir);
use Time::HiRes qw();

use constant TIMEOUT => 5;
use constant RRDDIR  => '/var/tmp';
use constant IMGDIR  => '/var/tmp';
use constant HOSTS => qw(
				mod_perl1.london.company.com
				mod_perl2.london.company.com
				mod_perl3.london.company.com
				mod_perl1.paris.company.com
				mod_perl2.paris.company.com
			);

use vars qw($VERSION $DEBUG $VERBOSE);
$VERSION = '0.02' || sprintf('%d', q$Revision: 965 $ =~ /(\d+)/g);
$DEBUG = $ENV{DEBUG} ? 1 : 0;
$VERBOSE = $ENV{VERBOSE} ? 1 : 0;

$| = 1;
$RRD::Simple::DEFAULT_DSTYPE = 'GAUGE';

our $ua = user_agent();
our $rrd = new RRD::Simple;



for my $host (sort loc_server HOSTS) {
	my $logs = {};

	TRACE("Processing $host ...");
	my $start_time = Time::HiRes::time();
	my $msg = "Processing $host";
	$VERBOSE && printf('%s %s ', $msg, '.' x (79 - length($msg) - 10));

	my ($status,$scoreboard) = parse_apache_status($ua,
			"http://$host:80/server-status?auto");
	my ($modules) = parse_perl_status($ua,
			"http://$host:80/perl-status?inc");
	$logs = parse_statlogs($ua, "http://$host:80/perl/statlogs.pl")
			unless keys(%{$logs});

	my %rrdfile = (
			status     => catdir(RRDDIR,"$host-status.rrd"),
			scoreboard => catdir(RRDDIR,"$host-scoreboard.rrd"),
			modules    => catdir(RRDDIR,"$host-modules.rrd"),
			logs       => catdir(RRDDIR,"$host-logs.rrd"),
		);

	if (keys %{$status}) {
		$status->{ReqPerSec} = $status->{TotalAccesses};
		$status->{KBPerSec} = $status->{TotalkBytes};

		if (!-f $rrdfile{status}) {
			my %def = %{$status};
			for (keys %def) {
				$def{$_} = $_ =~ /^ReqPerSec|KBPerSec$/i ?
						'DERIVE' : 'GAUGE';
			}

			eval {
				$rrd->create($rrdfile{status}, %def);
				RRDs::tune($rrdfile{status},'-i','ReqPerSec:0','-d','ReqPerSec:DERIVE');
				RRDs::tune($rrdfile{status},'-i','KBPerSec:0','-d','KBPerSec:DERIVE');
			};
			warn $@ if $@;
		}

		eval { $rrd->update($rrdfile{status}, %{$status}); };
		warn $@ if $@;
		generate_graphs($rrdfile{status},$host) unless $@;
	}

	if (keys %{$scoreboard}) {
		eval { $rrd->update($rrdfile{scoreboard}, %{$scoreboard}); };
		warn $@ if $@;
		generate_graphs($rrdfile{scoreboard},$host) unless $@;
	}

	if (keys %{$logs}) {
		if (!-f $rrdfile{logs}) {
			eval {
				$rrd->create($rrdfile{logs}, map {($_=>'DERIVE')} keys %{$logs}));
				RRDs::tune($rrdfile{logs},'-i',"$_:0") for
						$rrd->sources($rrdfile{logs});
			};
			warn $@ if $@;
		}

		eval { $rrd->update($rrdfile{logs}, map {($_=>$logs->{$_})} keys %{$logs})); };
		warn $@ if $@;
		generate_graphs($rrdfile{logs},$host) unless $@;
	}

	if (keys %{$modules}) {
		eval { $rrd->update($rrdfile{modules}, %{$modules}); };
		warn $@ if $@;
		generate_graphs($rrdfile{modules},$host) unless $@;
	}

	$VERBOSE && printf("[%6.2f]\n", Time::HiRes::time() - $start_time);
}



exit;



#####################################
# Subs init

sub loc_server {
	(split(/\./,$a))[1] cmp (split(/\./,$b))[1]
		||
	($a =~ /^mod_perl(\d+)/)[0] <=> ($b =~ /^mod_perl(\d+)/)[0]
}

sub generate_graphs {
	my ($rrdfile,$host) = @_;

	eval {
		if ($rrdfile =~ /status/) {
			$rrd->graph($rrdfile,
					basename => "$host-status-total",
					destination => IMGDIR,
					title => "$host Total x",
					vertical_label => 'Total x',
					sources => [ grep(/Total|Uptime/i,$rrd->sources($rrdfile)) ],
					line_thickness => 2,
				);
			$rrd->graph($rrdfile,
					basename => "$host-status-bytes2",
					destination => IMGDIR,
					title => "$host x/Sec",
					vertical_label => 'x/Sec',
					sources => [ grep(/KBPerSec|ReqPerSec/i,$rrd->sources($rrdfile)) ],
					line_thickness => 2,
				);
			$rrd->graph($rrdfile,
					basename => "$host-status-bytes",
					destination => IMGDIR,
					title => "$host Bytes/x",
					vertical_label => 'Bytes/x',
					sources => [ grep(/BytesPerSec|BytesPerReq/i,$rrd->sources($rrdfile)) ],
					line_thickness => 2,
				);
			$rrd->graph($rrdfile,
					basename => "$host-status-servers",
					destination => IMGDIR,
					title => "$host Servers",
					vertical_label => 'Children + Load',
					sources => [ grep(/Servers|CPULoad/i,$rrd->sources($rrdfile)) ],
					line_thickness => 2,
				);

		} elsif ($rrdfile =~ /scoreboard/) {
			$rrd->graph($rrdfile,
					destination => IMGDIR,
					title => "$host Scoreboard",
					line_thickness => 2,
					vertical_label => 'Apache Children',
					source_colors => [ qw(
						FF0000 00FF00 0000FF FFFF00 00FFFF FF00FF 000000
						AA0000 00AA00 0000AA AAAA00 00AAAA AA00AA AAAAAA
						550000 005500 000055 555500 005555 550055 555555
					) ],
				);

		} elsif ($rrdfile =~ /modules/) {
			$rrd->graph($rrdfile,
					basename => "$host-modules",
					destination => IMGDIR,
					vertical_label => 'Resident Modules',
					title => "$host Modules",
					line_thickness => 2,
				);

		} elsif ($rrdfile =~ /logs/) {
			$rrd->graph($rrdfile,
					basename => "$host-logs",
					destination => IMGDIR,
					title => "$host Logging/Sec",
					line_thickness => 2,
					vertical_label => 'bytes/sec',
					sources => [ sort($rrd->sources($rrdfile)) ],
				);
		}
	};
	warn $@ if $@;
}

sub parse_statlogs {
	my ($ua,$url) = @_;
	my %logs = ();

	my $response = $ua->get($url);
	if ($response->is_success) {
		for (split(/\n+|\r+/,$response->content)) {
			my ($file,$size,$modified) = split(/\s+/,$_);
			$logs{$file} = $size;
		}
	}

	DUMP('parse_statlogs(): \%logs',\%logs);
	return \%logs;
}

sub parse_perl_status {
	my ($ua,$url) = @_;
	my %modules = map {($_=>0)} qw(usr_lib other);

	my $response = $ua->get($url);
	if ($response->is_success) {
		for (split(/\n+|\r+/,$response->content)) {
			if (my ($module,$file) = $_ =~
					m,^<tr><td><a href="/perl-status\?(.+?)".+</td><td>(.+?)</td></tr>\s*$,) {

				local $_ = $file;
				if (m,^/usr/,) {
					$modules{usr_lib}++;
				} else {
					$modules{other}++;
				}
			}
		}
	}

	DUMP('parse_perl_status(): \%modules',\%modules);
	return \%modules;
}

sub parse_apache_status {
	my ($ua,$url) = @_;
	my %scoreboard = ();
	my %status = ();

	my %keys = (W => 'Write', G => 'GraceClose', D => 'DNS', S => 'Starting',
		L => 'Logging', R => 'Read', K => 'Keepalive', C => 'Closing',
		I => 'Idle', '_' => 'Waiting');

	my $response = $ua->get($url);
	if ($response->is_success) {
		for (split(/\n+|\r+/,$response->content)) {
			my ($k,$v) = $_ =~ /^\s*(.+?):\s+(.+?)\s*$/;
			$k =~ s/\s+//g; #$k = lc($k);
			if ($k eq 'Scoreboard') {
				my %x; $x{$_}++ for split(//,$v);
				%scoreboard = ( map { ($keys{$_}, $x{$_}) } keys %keys );
			} else {
				$status{$k} = $v;
			}
		}
	} else {
		TRACE("parse_apache_status(): failed to get $url; ".$response->status_line);
	}

	DUMP('parse_apache_status(): \%scoreboard',\%scoreboard);
	DUMP('parse_apache_status(): \%status',\%status);
	return (\%status,\%scoreboard);
}

sub user_agent {
	my $ua = LWP::UserAgent->new(
			agent => "RRD::Simple example $0 $VERSION",
			timeout => TIMEOUT,
		);
	$ua->env_proxy;
	$ua->max_size(1024*250);
	return $ua;
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

sub TRACE {
	return unless $DEBUG;
	warn(shift());
}

sub DUMP {
	return unless $DEBUG;
	eval {
		require Data::Dumper;
		warn(shift().': '.Data::Dumper::Dumper(shift()));
	}
}


1;


__END__



