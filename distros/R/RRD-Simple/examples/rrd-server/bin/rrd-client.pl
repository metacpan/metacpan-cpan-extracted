#!/usr/bin/perl -w
############################################################
#
#   $Id: rrd-client.pl 1092 2008-01-23 14:23:51Z nicolaw $
#   rrd-client.pl - Data gathering script for RRD::Simple
#
#   Copyright 2006,2007,2008 Nicola Worthington
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

############################################################
# User defined constants
use constant DB_MYSQL_DSN  => $ENV{DB_MYSQL_DSN} || 'DBI:mysql:mysql:localhost';
use constant DB_MYSQL_USER => $ENV{DB_MYSQL_USER} || undef;
use constant DB_MYSQL_PASS => $ENV{DB_MYSQL_PASS} || undef;

use constant NET_PING_HOSTS => $ENV{NET_PING_HOSTS} ?
		(split(/[\s,:]+/,$ENV{NET_PING_HOSTS})) : qw();

#
#  YOU SHOULD NOT NEED TO EDIT ANYTHING BEYOND THIS POINT
#
############################################################





use 5.004;
use strict;
#use warnings; # comment out for release
use vars qw($VERSION);

$VERSION = '1.42' || sprintf('%d', q$Revision: 1092 $ =~ /(\d+)/g);
$ENV{PATH} = '/bin:/usr/bin';
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};


# Default list of probes
my %probes = (
		hw_irq_interrupts    => 'Hardward IRQ Interrupts',

		cpu_utilisation      => 'CPU Utilisation',
		cpu_loadavg          => 'Load Average',
		cpu_temp             => 'CPU Temperature',
		cpu_interrupts       => 'CPU Interrupts',

		hdd_io               => 'Hard Disk I/O',
		hdd_temp             => 'Hard Disk Temperature',
		hdd_capacity         => 'Disk Capacity',

		mem_usage            => 'Memory Usage & Swap Usage',
		mem_swap_activity    => 'Swap Activity',
		mem_proc_largest     => 'Largest Process',

		proc_threads         => 'Threads',
		proc_state           => 'Processes',
		proc_filehandles     => 'File Handles',

		apache_status        => 'Apache Scoreboard & Apache Activity',
		apache_logs          => 'Apache Log Activity',

		misc_uptime          => 'Server Uptime',
		misc_users           => 'Users Logged In',
		misc_ipmi_temp       => 'IPMI Temperature Probes',
		misc_entropy         => 'Available Entropy',

		db_mysql_activity    => 'MySQL Database Activity',
		db_mysql_replication => 'MySQL Database Replication',

		mail_exim_queue      => 'Exim Mail Queue',
		mail_postfix_queue   => 'Postfix Mail Queue',
		mail_sendmail_queue  => 'Sendmail Mail Queue',

		net_traffic          => 'Network Traffic',
		net_connections      => 'Network Connections',
		net_ping_host        => 'Ping',
		# net_connections_ports => 'Service Connections',
	);


# Get command line options
my %opt = ();
eval "require Getopt::Std";
$Getopt::Std::STANDARD_HELP_VERSION = 1;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
Getopt::Std::getopts('p:i:x:s:c:V:hvqlP:?', \%opt) unless $@;
(HELP_MESSAGE() && exit) if defined $opt{h} || defined $opt{'?'};
(VERSION_MESSAGE() && exit) if defined $opt{v};

# Display a list of available probe names
if ($opt{l}) {
	print "Available probes:\n";
	printf "   %-24s %s\n",'PROBE','DESCRIPTION';
	for (sort keys %probes) {
		my $str = sprintf("   %-24s %s\n", $_, $probes{$_});
		$str =~ s/(\S+) (\s+) /$_ = "$1 ". '.' x length($2) ." ";/e;
		print "$str";
	}
	exit;
}

# Check to see if we are capable of SNMP queries
my $snmpClient;
if ($opt{s}) {
	eval {
		require Net::SNMP;
		$snmpClient = 'Net::SNMP';
	};
	if ($@) {
		my $c = 'snmpwalk'; # snmpget
		my $cmd = select_cmd("/usr/bin/$c","/usr/local/bin/$c");
		die "Error: unable to query via SNMP. Please install Net::SNMP or $c.\n" unless $cmd;
		$snmpClient = $cmd;
	}
	$opt{c} = 'public' unless defined($opt{c}) && $opt{c} =~ /\S+/;
	$opt{V} = '2c' unless defined($opt{V}) && $opt{V} =~ /^(1|2c)$/;
	$opt{P} = 161 unless defined($opt{P}) && $opt{P} =~ /^[0-9]+$/;
}

# Filter on probe include list
my @probes = sort keys %probes;
if (defined $opt{i}) {
	my $inc = join('|',split(/\s*,\s*/,$opt{i}));
	@probes = grep(/(^|_)($inc)(_|$)/,@probes);
}

# Filter on probe exclude list
if (defined $opt{x}) {
	my $exc = join('|',split(/\s*,\s*/,$opt{x}));
	@probes = grep(!/(^|_)($exc)(_|$)/,@probes);
}


# Run the probes one by one
die "Error: nothing to probe!\n" unless @probes;
my $post = '';
my %update_cache;
for my $probe (@probes) {
	eval {
		local $SIG{ALRM} = sub { die "Timeout!\n"; };
		alarm 15;
		my $str = report($probe,eval "$probe();");
		if (defined $opt{p}) {
			$post .= $str;
		} else {
			print $str;
		}
		warn "Warning [$probe]: $@" if !$opt{q} && $@;
		alarm 0;
	};
	warn "Warning [$probe]: $@" if !$opt{q} && $@;
}


# HTTP POST the data if asked to
print scalar(basic_http('POST',$opt{p},30,$post))."\n" if $opt{p};


exit;





# Report the data
sub report {
	(my $probe = shift) =~ s/[_-]/\./g;
	my %data = @_ % 2 ? (@_,undef) : @_;
	my $str = '';
	for my $k (sort keys %data) {
		#$data{$k} = 0 unless defined($data{$k});
		next unless defined($data{$k}) && $data{$k} =~ /^[0-9\.]*$/;
		$str .= sprintf("%s.%s.%s %s\n", time(), $probe, $k, $data{$k});
	}
	return $str;
}


# Display help
sub HELP_MESSAGE {
	print qq{Syntax: rrd-client.pl [-i probe1,probe2,..|-x probe1,probe2,..]
                      [-s host] [-c community] [-P port] [-V 1|2c] [-p URL] [-h|-v]
   -i <probes>     Include a list of comma seperated probes
   -x <probes>     Exclude a list of comma seperated probes
   -s <host>       Specify hostname to probe via SNMP
   -c <community>  Specify SNMP community name (defaults to public)
   -V <version>    Specify SNMP version to use (1 or 2c, defaults to 2c)
   -P <port>       Specify SNMP port to use
   -p <URL>        HTTP POST data to the specified URL
   -q              Suppress all warning messages
   -l              Display a list of available probe names
   -v              Display version information
   -h              Display this help

Examples:
   rrd-client.pl -x apache_status -q -p http://rrd.me.uk/cgi-bin/rrd-server.cgi
   rrd-client.pl -s localhost -p http://rrd.me.uk/cgi-bin/rrd-server.cgi
   rrd-client.pl -s server1.company.com | rrd-server.pl -u server1.company.com
\n};
}


# Display version
sub VERSION { &VERSION_MESSAGE; }
sub VERSION_MESSAGE {
	print "$0 version $VERSION ".'($Id: rrd-client.pl 1092 2008-01-23 14:23:51Z nicolaw $)'."\n";
}


# Basic HTTP client if LWP is unavailable
sub basic_http {
	my ($method,$url,$timeout,$data) = @_;
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
		print SOCK "User-Agent: $0 version $VERSION ".'($Id: rrd-client.pl 1092 2008-01-23 14:23:51Z nicolaw $)'."\n";
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

	warn "Warning [basic_http]: $@" if !$opt{q} && $@ && $data;
	return wantarray ? split(/\n/,$str) : "$str";
}


# Return the most appropriate binary command
sub select_cmd {
	foreach (@_) {
		if (-f $_ && -x $_ && /(\S+)/) {
			return $1;
		}
	}
	return '';
}






#
# Probes
#


sub _snmp {
	my $oid = [@_];
	my $result = {};

	# Net::SNMP
	if ($snmpClient eq 'Net::SNMP') {
		my ($session, $error) = Net::SNMP->session(
				-hostname  => $opt{s},
				-community => $opt{c},
				-version   => $opt{V},
				-port      => $opt{P},
				-translate => [ -timeticks => 0x0 ],
			);
		die $error if !defined($session);

		$result = $session->get_request(-varbindlist => $oid);

		$session->close;
		die $session->error if !defined($result);

	# snmpget / snmpwalk
	} else {
		my $oidStr = join(' ', @{$oid});
		my $cmd = "$snmpClient -O n -O t -v $opt{V} -c $opt{c} $opt{s} $oidStr";
		#my $cmd = "$snmpClient -O t -v $opt{V} -c $opt{c} $opt{s} $oidStr";

		open(PH,'-|',"$cmd 2>&1") || die "Unable to open file handle PH for command '$cmd': $!\n";
		while (local $_ = <PH>) {
			s/[\r\n]+//g; s/^(?:\s+|\s+)$//g;
			if (/^(\.[\.0-9]+|[A-Za-z:\-\.0-9]+)\s*=\s*(?:([A-Za-z0-9]+):\s*)?["']?(\S*)["']?/) {
				my ($oid,$type,$value) = ($1,$2,$3);
				$oid = ".$oid" if $oid =~ /^[0-9][0-9\.]+$/;
				$result->{$oid} = $value;
			} else {
				warn "Warning [_snmp]: $_\n" unless $opt{q};
			}
		}
	        close(PH) || die "Unable to close file handle PH for command '$cmd': $!\n";
	}

	return $result->{(keys(%{$result}))[0]} if !wantarray && keys(%{$result}) == 1;
	return $result;
}



sub net_ping_host {
	return if $opt{s};
	return unless defined NET_PING_HOSTS() && scalar NET_PING_HOSTS() > 0;
	my $cmd = select_cmd(qw(/bin/ping /usr/bin/ping /sbin/ping /usr/sbin/ping));
	return unless -f $cmd;
	my %update = ();
	my $count = 3;

	for my $str (NET_PING_HOSTS()) {
		my ($host) = $str =~ /^([\w\d_\-\.]+)$/i;
		next unless $host;
		my $cmd2 = "$cmd -c $count $host 2>&1";

		open(PH,'-|',$cmd2) || die "Unable to open file handle PH for command '$cmd2': $!\n";
		while (local $_ = <PH>) {
			if (/\s+(\d+)%\s+packet\s+loss[\s,]/i) {
				$update{"$host.PacketLoss"} = $1 || 0;
			} elsif (my ($min,$avg,$max,$mdev) = $_ =~
					/\s+([\d\.]+)\/([\d\.]+)\/([\d\.]+)\/([\d\.]+)\s+/) {
				$update{"$host.AvgRTT"} = $avg || 0;
				$update{"$host.MinRTT"} = $min || 0;
				$update{"$host.MaxRTT"} = $max || 0;
				$update{"$host.MDevRTT"} = $mdev || 0;
			}
		}
		close(PH) || die "Unable to close file handle PH for command '$cmd2': $!\n";
	}

	return %update;
}



sub mem_proc_largest {
	return if $opt{s};
	my $cmd = select_cmd(qw(/bin/ps /usr/bin/ps));
	return unless -f $cmd;
	$cmd .= ' -eo vsize';

	my %update = ();
	open(PH,'-|',$cmd) || die "Unable to open file handle PH for command '$cmd': $!\n";
	while (local $_ = <PH>) {
		if (/(\d+)/) {
			my $kb = $1;
			$update{LargestProc} = $kb if !defined $update{LargestProc} ||
				(defined $update{LargestProc} && $kb > $update{LargestProc});
		}
	}
	close(PH) || die "Unable to close file handle PH for command '$cmd': $!\n";
	$update{LargestProc} *= 1024 if defined $update{LargestProc};

	return %update;
}



sub proc_threads {
	if ($opt{s}) {
		my $procs = _snmp('.1.3.6.1.2.1.25.1.6.0'); # hrSystemProcesses
		return unless defined($procs) && $procs =~ /^[0-9]+$/;
		return ('Processes' => $procs, 'Threads' => 0, 'MultiThreadProcs' => 0);
	}

	return if $opt{s};
	return unless ($^O eq 'linux' && `/bin/uname -r 2>&1` =~ /^2\.6\./) ||
			($^O eq 'solaris' && `/bin/uname -r 2>&1` =~ /^5\.9/);
	my %update = ();
	my $cmd = '/bin/ps -eo pid,nlwp';

	open(PH,'-|',$cmd) || die "Unable to open file handle PH for command '$cmd': $!";
	while (local $_ = <PH>) {
		if (my ($pid,$nlwp) = $_ =~ /^\s*(\d+)\s+(\d+)\s*$/) {
			$update{Processes}++;
			$update{Threads} += $nlwp;
			$update{MultiThreadProcs}++ if $nlwp > 1;
		}
	}
	close(PH) || die "Unable to close file handle PH for command '$cmd': $!";

	return %update;
}



sub mail_exim_queue {
	return if $opt{s};
	my $spooldir = '/var/spool/exim/input';
	return unless -d $spooldir && -x $spooldir && -r $spooldir;

	local %mail::exim::queue::update = (Messages => 0);
	require File::Find;
	File::Find::find({wanted => sub {
			my ($dev,$ino,$mode,$nlink,$uid,$gid);
			(($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) &&
			-f _ &&
			/^.*-D\z/s &&
			$mail::exim::queue::update{Messages}++;
		}, no_chdir => 1}, $spooldir);
	return %mail::exim::queue::update;
}


sub mail_sendmail_queue {
	return if $opt{s};
	my $spooldir = '/var/spool/mqueue';
	return unless -d $spooldir && -x $spooldir && -r $spooldir;

	local %mail::sendmail::queue::update = (Messages => 0);
	require File::Find;
	File::Find::find({wanted => sub {
			my ($dev,$ino,$mode,$nlink,$uid,$gid);
			(($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) &&
			-f _ &&
			/^Qf[a-zA-Z0-9]{14}\z/s &&
			$mail::sendmail::queue::update{Messages}++;
		}, no_chdir => 1}, $spooldir);
	return %mail::sendmail::queue::update;
}



sub mail_postfix_queue {
	return if $opt{s};
	my @spooldirs = qw(
			/var/spool/postfix/incoming
			/var/spool/postfix/active
			/var/spool/postfix/defer
			/var/spool/postfix/deferred
		);
	for my $spooldir (@spooldirs) {
		return unless -d $spooldir && -x $spooldir && -r $spooldir;
	}

	local %mail::postfix::queue::update = (Messages => 0);
	require File::Find;
	File::Find::find({wanted => sub {
			my ($dev,$ino,$mode,$nlink,$uid,$gid);
			(($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) &&
			-f _ &&
			$mail::postfix::queue::update{Messages}++;
		}, no_chdir => 1}, @spooldirs);
	return %mail::postfix::queue::update;
}



# DO NOT ENABLE THIS ONE YET
sub mail_queue {
	return if $opt{s};
	my $cmd = select_cmd(qw(/usr/bin/mailq /usr/sbin/mailq /usr/local/bin/mailq
			/usr/local/sbin/mailq /bin/mailq /sbin/mailq
			/usr/local/exim/bin/mailq /home/system/exim/bin/mailq));
	return unless -f $cmd;

	my %update = ();

	open(PH,'-|',$cmd) || die "Unable to open file handle PH for command '$cmd': $!\n";
	while (local $_ = <PH>) {
		# This needs to match a single message id = currently only exim friendly
		if (/^\s*\S+\s+\S+\s+[a-z0-9]{6}-[a-z0-9]{6}-[a-z0-9]{2} </i) {
			$update{Messages}++;
		}
	}
	close(PH) || die "Unable to close file handle PH for command '$cmd': $!\n";
	$update{Messages} = 0 if !defined($update{Messages});

	return %update;
}



sub db_mysql_activity {
	return if $opt{s};
	my %update = ();
	return %update unless (defined DB_MYSQL_DSN && defined DB_MYSQL_USER);
	my @cols = qw(Com_select Com_insert Com_delete Com_replace Com_update Questions);

#	my @GAUGE = qw(Key_blocks_not_flushed Key_blocks_unused Key_blocks_used
#		Open_files Open_streams Open_tables Qcache_free_blocks Qcache_free_memory
#		Qcache_queries_in_cache Qcache_total_blocks Slave_open_temp_tables
#		Threads_cached Threads_connected Threads_running Uptime);

#	my @DERIVE = qw(Aborted_clients Aborted_connects Binlog_cache_disk_use
#		Binlog_cache_use Bytes_received Bytes_sent Com_admin_commands Com_alter_db
#		Com_alter_table Com_analyze Com_backup_table Com_begin Com_change_db
#		Com_change_master Com_check Com_checksum Com_commit Com_create_db
#		Com_create_function Com_create_index Com_create_table Com_dealloc_sql
#		Com_delete Com_delete_multi Com_do Com_drop_db Com_drop_function
#		Com_drop_index Com_drop_table Com_drop_user Com_execute_sql Com_flush
#		Com_grant Com_ha_close Com_ha_open Com_ha_read Com_help Com_insert
#		Com_insert_select Com_kill Com_load Com_load_master_data Com_load_master_table
#		Com_lock_tables Com_optimize Com_preload_keys Com_prepare_sql Com_purge
#		Com_purge_before_date Com_rename_table Com_repair Com_replace Com_replace_select
#		Com_reset Com_restore_table Com_revoke Com_revoke_all Com_rollback
#		Com_savepoint Com_select Com_set_option Com_show_binlog_events
#		Com_show_binlogs Com_show_charsets Com_show_collations Com_show_column_types
#		Com_show_create_db Com_show_create_table Com_show_databases
#		Com_show_errors Com_show_fields Com_show_grants Com_show_innodb_status
#		Com_show_keys Com_show_logs Com_show_master_status Com_show_ndb_status
#		Com_show_new_master Com_show_open_tables Com_show_privileges Com_show_processlist
#		Com_show_slave_hosts Com_show_slave_status Com_show_status Com_show_storage_engines
#		Com_show_tables Com_show_variables Com_show_warnings Com_slave_start
#		Com_slave_stop Com_stmt_close Com_stmt_execute Com_stmt_prepare Com_stmt_reset
#		Com_stmt_send_long_data Com_truncate Com_unlock_tables Com_update
#		Com_update_multi Connections Created_tmp_disk_tables Created_tmp_files
#		Created_tmp_tables Delayed_errors Delayed_insert_threads Delayed_writes
#		Flush_commands Handler_commit Handler_delete Handler_discover Handler_read_first
#		Handler_read_key Handler_read_next Handler_read_prev Handler_read_rnd
#		Handler_read_rnd_next Handler_rollback Handler_update Handler_write
#		Key_blocks_not_flushed Key_blocks_unused Key_blocks_used Key_read_requests
#		Key_reads Key_write_requests Key_writes Max_used_connections Not_flushed_delayed_rows
#		Open_files Open_streams Open_tables Opened_tables Qcache_free_blocks
#		Qcache_free_memory Qcache_hits Qcache_inserts Qcache_lowmem_prunes Qcache_not_cached
#		Qcache_queries_in_cache Qcache_total_blocks Questions Select_full_join
#		Select_full_range_join Select_range Select_range_check Select_scan Slave_open_temp_tables
#		Slave_retried_transactions Slow_launch_threads Slow_queries Sort_merge_passes
#		Sort_range Sort_rows Sort_scan Ssl_accept_renegotiates Ssl_accepts
#		Ssl_callback_cache_hits Ssl_client_connects Ssl_connect_renegotiates Ssl_ctx_verify_depth
#		Ssl_ctx_verify_mode Ssl_default_timeout Ssl_finished_accepts Ssl_finished_connects
#		Ssl_session_cache_hits Ssl_session_cache_misses Ssl_session_cache_overflows
#		Ssl_session_cache_size Ssl_session_cache_timeouts Ssl_sessions_reused
#		Ssl_used_session_cache_entries Ssl_verify_depth Ssl_verify_mode
#		Table_locks_immediate Table_locks_waited Threads_cached Threads_connected
#		Threads_created Threads_running);

	eval {
		require DBI;
		my $dbh = DBI->connect(DB_MYSQL_DSN,DB_MYSQL_USER,DB_MYSQL_PASS);
		my $sth = $dbh->prepare('SHOW GLOBAL STATUS');
		$sth->execute();
		while (my @ary = $sth->fetchrow_array()) {
			if (grep { $ary[0] eq $_ && /^Com_/ } @cols) {
				$update{"com.$ary[0]"} = $ary[1];
			} elsif (grep { $ary[0] eq $_ } @cols) {
				$update{$ary[0]} = $ary[1];
			}
		}
		$sth->finish();
		$dbh->disconnect();
	};

	return %update;
}



sub db_mysql_replication {
	return if $opt{s};
	my %update = ();
	return %update unless (defined DB_MYSQL_DSN && defined DB_MYSQL_USER);

	eval {
		require DBI;
		my $dbh = DBI->connect(DB_MYSQL_DSN,DB_MYSQL_USER,DB_MYSQL_PASS);
		my $sth = $dbh->prepare('SHOW SLAVE STATUS');
		$sth->execute();
		my $row = $sth->fetchrow_hashref;
		$sth->finish();
		$dbh->disconnect();
		$update{SecondsBehind} = $row->{Seconds_Behind_Master} || 0;
	};

	return %update;
}



sub misc_users {
	if ($opt{s}) {
		my $users = _snmp('.1.3.6.1.2.1.25.1.5.0'); # hrSystemNumUsers
		return unless defined($users) && $users =~ /^[0-9]+$/;
		return ('Users' => $users, 'Unique' => 0);
	}

	return if $opt{s};
	my $cmd = select_cmd(qw(/usr/bin/who /bin/who /usr/bin/w /bin/w));
	return unless -f $cmd;
	my %update = ();

	open(PH,'-|',$cmd) || die "Unable to open file handle PH for command '$cmd': $!\n";
	my %users = ();
	while (local $_ = <PH>) {
		next if /^\s*USERS\s*TTY/;
		$users{(split(/\s+/,$_))[0]}++;
		$update{Users}++;
	}
	close(PH) || die "Unable to close file handle PH for command '$cmd': $!\n";
	$update{Unique} = keys %users if keys %users;

	unless (keys %update) {
		$cmd = -f '/usr/bin/uptime' ? '/usr/bin/uptime' : '/bin/uptime';
		if (my ($users) = `$cmd` =~ /,\s*(\d+)\s*users?\s*,/i) {
			$update{Users} = $1;
		}
	}

	$update{Users} ||= 0;
	$update{Unique} ||= 0;

	return %update;
}



sub misc_uptime {
	if ($opt{s}) {
		my $ticks = _snmp('.1.3.6.1.2.1.25.1.1.0'); # hrSystemUptime
		return unless defined($ticks) && $ticks =~ /^[0-9]+$/;
		return ('DaysUp' => $ticks/100/60/60/24);
	}

	my $cmd = select_cmd(qw(/usr/bin/uptime /bin/uptime));
	return unless -f $cmd;
	my %update = ();

	if (my ($str) = `$cmd` =~ /\s*up\s*(.+?)\s*,\s*\d+\s*users?/) {
		my $days = 0;
		if (my ($nuke,$num) = $str =~ /(\s*(\d+)\s*days?,?\s*)/) {
			$str =~ s/$nuke//;
			$days += $num;
		}
		if (my ($nuke,$mins) = $str =~ /(\s*(\d+)\s*mins?,?\s*)/) {
			$str =~ s/$nuke//;
			$days += ($mins / (60*24));
		}
		if (my ($nuke,$hours) = $str =~ /(\s*(\d+)\s*(hour|hr)s?,?\s*)/) {
			$str =~ s/$nuke//;
			$days += ($hours / 24);
		}
		if (my ($hours,$mins) = $str =~ /\s*(\d+):(\d+)\s*,?/) {
			$days += ($mins / (60*24));
			$days += ($hours / 24);
		}
		$update{DaysUp} = $days;
	}

	return %update;
}



sub cpu_temp {
	return if $opt{s};
	my $cmd = '/usr/bin/sensors';
	return unless -f $cmd;
	my %update = ();

	open(PH,'-|',"$cmd 2>&1") || die "Unable to open file handle PH for command '$cmd': $!\n";
	while (local $_ = <PH>) {
		if (my ($k,$v) = $_ =~ /^([^:]*\b(?:CPU|temp)\d*\b.*?):\s*\S*?([\d\.]+)\S*\s*/i) {
			$k =~ s/\W//g; $k =~ s/Temp$//i;
			$update{$k} = $v;
                } elsif (/(no sensors found|kernel driver|sensors-detect|error|warning)/i
				&& !$opt{q}) {
                        warn "Warning [cpu_temp]: $_";
                }
	}
	close(PH) || die "Unable to close file handle PH for command '$cmd': $!\n";

	return %update;
}



sub apache_logs {
	return if $opt{s};
	my $dir = '/var/log/httpd';
	return unless -d $dir;
	my %update = ();

	if (-d $dir) {
		opendir(DH,$dir) || die "Unable to open file handle for directory '$dir': $!\n";
		my @files = grep(!/^\./,readdir(DH));
		closedir(DH) || die "Unable to close file handle for directory '$dir': $!\n";
		for (@files) {
			next if /\.(\d+|gz|bz2|Z|zip|old|bak|pid|backup)$/i || /[_\.\-]pid$/;
			my $file = "$dir/$_";
			next unless -f $file;
			s/[\.\-]/_/g;
			$update{$_} = (stat($file))[7];
		}
	}

	return %update;
}



sub apache_status {
	return if $opt{s};
	my @data = ();
	my %update = ();

	my $timeout = 5;
	my $url = 'http://localhost/server-status?auto';
	my %keys = (W => 'Write', G => 'GraceClose', D => 'DNS', S => 'Starting',
		L => 'Logging', R => 'Read', K => 'Keepalive', C => 'Closing',
		I => 'Idle', '_' => 'Waiting');


	eval "use LWP::UserAgent";
	unless ($@) {
		eval {
			my $ua = LWP::UserAgent->new(
				agent => "$0 version $VERSION ".'($Id)',
				 timeout => $timeout);
			$ua->env_proxy;
			$ua->max_size(1024*250);
			my $response = $ua->get($url);
			if ($response->is_success) {
				@data = split(/\n+|\r+/,$response->content);
			} elsif (!$opt{q}) {
				warn "Warning [apache_status]: failed to get $url; ". $response->status_line ."\n";
			}
		};
	}
	if ($@) {
		@data = basic_http('GET',$url,$timeout);
	}

	for (@data) {
		my ($k,$v) = $_ =~ /^\s*(.+?):\s+(.+?)\s*$/;
		$k = '' unless defined $k;
		$v = '' unless defined $v;
		$k =~ s/\s+//g; #$k = lc($k);
		next unless $k;
		if ($k eq 'Scoreboard') {
			my %x; $x{$_}++ for split(//,$v);
			for (keys %keys) {
				$update{"scoreboard.$keys{$_}"} = 
					defined $x{$_} ? $x{$_} : 0;
			}
		} else {
			$update{$k} = $v;
		}
	}

	$update{ReqPerSec} = int($update{TotalAccesses})
		if defined $update{TotalAccesses};
	$update{BytesPerSec} = int($update{TotalkBytes} * 1024)
		if defined $update{TotalkBytes};

	return %update;
}



sub _darwin_cpu_utilisation {
	my $output = qx{/usr/bin/sar 4 1};
	my %rv = ();
	if ($output =~ m/Average:\s+(\d+)\s+(\d+)\s+(\d+)/) {
		%rv = (
				User => $1,
				System => $2,
				Idle => $3,
				IO_Wait => 0, # at the time of writing, sar doesn't provide this metric
			);
	}
	return %rv;
}



sub cpu_utilisation {
	my %update = ();
	if ($opt{s}) {
		$update{'User'}    = _snmp('.1.3.6.1.4.1.2021.11.9.0');
		$update{'System'}  = _snmp('.1.3.6.1.4.1.2021.11.10.0');
		$update{'Idle'}    = _snmp('.1.3.6.1.4.1.2021.11.11.0');
		#$update{'IO_Wait'} = 100 - $update{'User'} - $update{'System'} - $update{'Idle'};
		$update{'IO_Wait'} = 0;

		# Try querying the Windows thingie instead
		unless (grep(/^[0-9\.]{1,3}$/, values(%update)) == 4) {
			# hrProcessorLoad
			# .1.3.6.1.2.1.25.3.3.1.2.1 - CPU 1
			# .1.3.6.1.2.1.25.3.3.1.2.2 - CPU 2 ...
			my $total; my $cpu;
			for ($cpu = 1; $cpu <= 16; $cpu++) {
				my $load = _snmp(".1.3.6.1.2.1.25.3.3.1.2.$cpu");
				if (defined($load) && !ref($load) && $load =~ /^[0-9\.]{1,3}$/) {
					$total += $load;
				} else {
					last;
				}
			}
			return unless $total && $cpu-1;
			%update = ('User' => int($total / $cpu-1), 'System' => 0, 'Idle' => 0, 'IO_Wait' => 0);
		}
		return %update;
	}

	if ($^O eq 'darwin') {
		return _darwin_cpu_utilisation();
	}

	my $cmd = '/usr/bin/vmstat';
	return unless -f $cmd;
	%update = _parse_vmstat("$cmd 1 2");
	my %labels = (wa => 'IO_Wait', id => 'Idle', sy => 'System', us => 'User');

	$update{$_} ||= 0 for keys %labels;
	return ( map {( $labels{$_} || $_ => $update{$_} )} keys %labels );
}



sub hw_irq_interrupts {
	return if $opt{s};

	my @update;
	if (open(FH,'<','/proc/interrupts')) {
		local $_ = <FH>;
		return unless /^\s+(CPU[0-9]+.*)/;
		my @cpus = split(/\s+/,$1);
		$_ = lc($_) for @cpus;

		my %data;
		while (local $_ = <FH>) {
			if (/^\s*([0-9]{1,2}):\s+([\s0-9]+)\s+(\S+)\s+(.+?)\s*$/) {
				my ($irq,$ints,$path,$src) = ($1,$2,$3,$4);
				my @ints = split(/\s+/,$ints);
				for (my $i = 0; $i <= @cpus; $i++) {
					my $cpu = $cpus[$i];
					my $int = $ints[$i];
					next unless defined $cpu && defined $int;
					$data{$cpu}->{"$cpu.irq$irq"} = $int;
				}
			}
		}

		for my $cpu (keys %data) {
			if (grep(/[1-9]/,values %{$data{$cpu}})) {
				push @update, %{$data{$cpu}};
			}
		}

		close(FH) || warn "Unable to close file handle FH for file '/proc/interrupts': $!";
	}

	return @update;
}



sub cpu_interrupts {
	return if $opt{s};
	my $cmd = '/usr/bin/vmstat';
	return unless -f $cmd;

	my %update = _parse_vmstat("$cmd 1 2");
	my %labels = (in => 'Interrupts');
	return unless defined $update{in};

	$update{$_} ||= 0 for keys %labels;
	return ( map {( $labels{$_} || $_ => $update{$_} )} keys %labels );
}



sub mem_swap_activity {
	return if $opt{s};
	my $cmd = '/usr/bin/vmstat';
	return unless -f $cmd;

	my %update = _parse_vmstat("$cmd 1 2");
	my %labels = (si => 'Swap_In', so => 'Swap_Out');
	return unless defined $update{si} && defined $update{so};

	$update{$_} ||= 0 for keys %labels;
	return ( map {( $labels{$_} || $_ => $update{$_} )} keys %labels );
}



sub _parse_vmstat {
	my $cmd = shift;
	my %update;
	my @keys;

	if (exists $update_cache{vmstat}) {
		%update = %{$update_cache{vmstat}};
	} else {
		open(PH,'-|',$cmd) || die "Unable to open file handle PH for command '$cmd': $!\n";
		while (local $_ = <PH>) {
			s/^\s+|\s+$//g;
			if (/\s+\d+\s+\d+\s+\d+\s+/ && @keys) {
				@update{@keys} = split(/\s+/,$_);
			} else { @keys = split(/\s+/,$_); }
		}
		close(PH) || die "Unable to close file handle PH for command '$cmd': $!\n";
		$update_cache{vmstat} = \%update;
	}

	return %update;
}



sub _parse_ipmitool_sensor {
	my $cmd = shift;
	my %update;
	my @keys;

	if (exists $update_cache{ipmitool_sensor}) {
		%update = %{$update_cache{ipmitool_sensor}};
	} else {
		if ((-e '/dev/ipmi0' || -e '/dev/ipmi/0') && open(PH,'-|',$cmd)) {
			while (local $_ = <PH>) {
					chomp; s/(^\s+|\s+$)//g;
					my ($key,@ary) = split(/\s*\|\s*/,$_);
					$key =~ s/[^a-zA-Z0-9_]//g;
					$update{$key} = \@ary;
			}
			close(PH);
			$update_cache{ipmitool_sensor} = \%update;
		}
	}

	return %update;
}



sub misc_ipmi_temp {
	return if $opt{s};
	my $cmd = select_cmd(qw(/usr/bin/ipmitool));
	return unless -f $cmd;

	my %update = ();
	my %data = _parse_ipmitool_sensor("$cmd sensor");
	for (grep(/temp/i,keys %data)) {
		$update{$_} = $data{$_}->[0]
			if $data{$_}->[0] =~ /^[0-9\.]+$/;
	}
	return unless keys %update;

	return %update;;
}



sub hdd_io {
	return if $opt{s};
	my $cmd = select_cmd(qw(/usr/bin/iostat /usr/sbin/iostat));
	return unless -f $cmd;
	return unless $^O eq 'linux';
	$cmd .= ' -k';

	my %update = ();

	open(PH,'-|',$cmd) || die "Unable to open file handle PH for command '$cmd': $!\n";
	while (local $_ = <PH>) {
		if (my ($dev,$r,$w) = $_ =~ /^([\w\d]+)\s+\S+\s+\S+\s+\S+\s+(\d+)\s+(\d+)$/) {
			$update{"$dev.Read"} = $r*1024;
			$update{"$dev.Write"} = $w*1024;
		}
	}
	close(PH) || die "Unable to close file handle PH for command '$cmd': $!\n";

	return %update;
}



sub mem_usage {
	return if $opt{s};
	my %update = ();
	my $cmd = select_cmd(qw(/usr/bin/free /bin/free));
	my @keys = ();

	if ($^O eq 'linux' && -f $cmd && -x $cmd) {
		$cmd .= ' -b';
		open(PH,'-|',$cmd) || die "Unable to open file handle PH for command '$cmd': $!\n";
		while (local $_ = <PH>) {
			if (@keys && /^Mem:\s*(\d+.+)\s*$/i) {
				my @values = split(/\s+/,$1);
				for (my $i = 0; $i < @values; $i++) {
					$update{ucfirst($keys[$i])} = $values[$i];
				}
				$update{Used} = $update{Used} - $update{Buffers} - $update{Cached};

			} elsif (@keys && /^Swap:\s*(\d+.+)\s*$/i) {
				my @values = split(/\s+/,$1);
				for (my $i = 0; $i < @values; $i++) {
					$update{"swap.".ucfirst($keys[$i])} = $values[$i];
				}

			} elsif (!@keys && /^\s*([\w\s]+)\s*$/) {
				@keys = split(/\s+/,$1);
			}
		}
		close(PH) || die "Unable to close file handle PH for command '$cmd': $!\n";

	} elsif ($^O eq 'darwin' && -x '/usr/sbin/sysctl') {
		my $swap = qx{/usr/sbin/sysctl vm.swapusage};
		if ($swap =~ m/total = (.+)M  used = (.+)M  free = (.+)M/) {
			$update{"swap.Total"} = $1*1024*1024;
			$update{"swap.Used"} = $2*1024*1024;
			$update{"swap.Free"} = $3*1024*1024;
		}

	} else {
		eval "use Sys::MemInfo qw(totalmem freemem)";
		die "Please install Sys::MemInfo so that I can get memory information.\n" if $@;
		@update{qw(Total Free)} = (totalmem(),freemem());
	}

	return %update;
}



sub hdd_temp {
	return if $opt{s};
	my $cmd = select_cmd(qw(/usr/sbin/hddtemp /usr/bin/hddtemp));
	return unless -f $cmd;

	my @devs = ();
	for my $dev (glob('/dev/hd?'),glob('/dev/sd?')) {
		if ($dev =~ /^(\/dev\/\w{3})$/i) {
			push @devs, $1;
		}
	}

	$cmd .= " -q @devs 2>&1";
	my %update = ();
	return %update unless @devs;

	open(PH,'-|',$cmd) || die "Unable to open file handle PH for command '$cmd': $!\n";
	while (local $_ = <PH>) {
		if (my ($dev,$temp) = $_ =~ m,^/dev/([a-z]+):\s+.+?:\s+(\d+)..?C,) {
			$update{$dev} = $temp;
		} elsif (!/^\s*$/ && !$opt{q}) {
			warn "Warning [hdd_temp]: $_";
		}
	}
	close(PH) || die "Unable to close file handle PH for command '$cmd': $!\n";

	return %update;
}



sub hdd_capacity {
	if ($opt{s}) {
		return;

		my $snmp = _snmp('.1.3.6.1.4.1.2021.9.1'); # dskTable
		return unless defined($snmp) && ref($snmp) eq 'HASH';

		my %disks;
#.1.3.6.1.4.1.2021.9.1.1.1 = INTEGER: 1
#.1.3.6.1.4.1.2021.9.1.2.1 = STRING: /
#.1.3.6.1.4.1.2021.9.1.3.1 = STRING: /dev/sda1
#.1.3.6.1.4.1.2021.9.1.4.1 = INTEGER: 100000
#.1.3.6.1.4.1.2021.9.1.5.1 = INTEGER: -1
#.1.3.6.1.4.1.2021.9.1.6.1 = INTEGER: 7850996
#.1.3.6.1.4.1.2021.9.1.7.1 = INTEGER: 3153808
#.1.3.6.1.4.1.2021.9.1.8.1 = INTEGER: 4298376
#.1.3.6.1.4.1.2021.9.1.9.1 = INTEGER: 58
#.1.3.6.1.4.1.2021.9.1.10.1 = INTEGER: 16
#.1.3.6.1.4.1.2021.9.1.100.1 = INTEGER: 0
#.1.3.6.1.4.1.2021.9.1.101.1 = STRING: 

#'UCD-SNMP-MIB::dskMinimum.1' => '100000',
#'UCD-SNMP-MIB::dskErrorMsg.1' => '',
#'UCD-SNMP-MIB::dskIndex.1' => '1',
#'UCD-SNMP-MIB::dskPath.1' => '/',
#'UCD-SNMP-MIB::dskPercentNode.1' => '16',
#'UCD-SNMP-MIB::dskErrorFlag.1' => '0',
#'UCD-SNMP-MIB::dskAvail.1' => '3153784',
#'#UCD-SNMP-MIB::dskPercent.1' => '58',
#'UCD-SNMP-MIB::dskMinPercent.1' => '-1',
#'UCD-SNMP-MIB::dskDevice.1' => '/dev/sda1',
#'UCD-SNMP-MIB::dskUsed.1' => '4298400',
#'UCD-SNMP-MIB::dskTotal.1' => '7850996'

#use Data::Dumper;
#warn Dumper($snmp);
		return;
	}

	my $cmd = select_cmd(qw(/bin/df /usr/bin/df));
	return unless -f $cmd;

	if ($^O eq 'linux') { $cmd .= ' -P -x iso9660 -x nfs -x smbfs'; }
	elsif ($^O eq 'solaris') { $cmd .= ' -lk -F ufs'; }
	elsif ($^O eq 'darwin') { $cmd .= ' -P -T hfs,ufs'; }
	else { $cmd .= ' -P'; }

	my %update = ();
	my %variants = (
			'' => '',
			'inodes.' => ' -i ',
		);

	for my $variant (keys %variants) {
		my $variant_cmd = "$cmd $variants{$variant}";
		my @data = split(/\n/, `$variant_cmd`);
		shift @data;

		my @cols = qw(fs blocks used avail capacity mount unknown);
		for (@data) {
			my %data = ();
			@data{@cols} = split(/\s+/,$_);
			if ($^O eq 'darwin' || defined $data{unknown}) {
				@data{@cols} = $_ =~ /^(.+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%?\s+(.+)\s*$/;
			}

			next if ($data{fs} eq 'none' || $data{mount} =~ m#^/dev/#);
			$data{capacity} =~ s/\%//;
			(my $ds = $data{mount}) =~ s/[^a-z0-9]/_/ig; $ds =~ s/__+/_/g;

                        # McAfee SCM 4.2 bodge-o-rama fix work around
                        next if $ds =~ /^_var_jails_d_spam_/;

			$update{"${variant}$ds"} = $data{capacity};
		}
	}

	return %update;
}



sub misc_entropy {
	return if $opt{s};
	my $file = '/proc/sys/kernel/random/entropy_avail';
	return unless -f $file;
	my %update = ();

	open(FH,'<',$file) || die "Unable to open '$file': $!\n";
	chomp($update{entropy_avail} = <FH>);
	close(FH) || die "Unable to close '$file': $!\n";

	return %update;
}



sub net_traffic {
	return if $opt{s};
	return unless -f '/proc/net/dev';
	my @keys = ();
	my %update = ();

	open(FH,'<','/proc/net/dev') || die "Unable to open '/proc/net/dev': $!\n";
	while (local $_ = <FH>) {
		s/^\s+|\s+$//g;
		if ((my ($dev,$data) = $_ =~ /^(.+?):\s*(\d+.+)\s*$/) && @keys) {
			my @values = split(/\s+/,$data);
			for (my $i = 0; $i < @keys; $i++) {
				if ($keys[$i] eq 'TXbytes') {
					$update{"$dev.Transmit"} = $values[$i];
				} elsif ($keys[$i] eq 'RXbytes') {
					$update{"$dev.Receive"} = $values[$i];
				}
				#$update{"$dev.$keys[$i]"} = $values[$i];
			}
		} else {
			my ($rx,$tx) = (split(/\s*\|\s*/,$_))[1,2];
			@keys = (map({"RX$_"} split(/\s+/,$rx)), map{"TX$_"} split(/\s+/,$tx));
		}
	}
	close(FH) || die "Unable to close '/proc/net/dev': $!\n";

	return %update;
}



sub proc_state {
	return if $opt{s};
	my $cmd = select_cmd(qw(/bin/ps /usr/bin/ps));
	my %update = ();
	my %keys = ();

	if (-f $cmd && -x $cmd) {
		if ($^O eq 'freebsd' || $^O eq 'darwin') {
			$cmd .= ' axo pid,state';
		#	%keys = (D => 'IO_Wait', R => 'Run', S => 'Sleep', T => 'Stopped',
		#			I => 'Idle', L => 'Lock_Wait', Z => 'Zombie', W => 'Idle_Thread');
			%keys = (D => 'IO_Wait', R => 'Run', S => 'Sleep', T => 'Stopped',
					W => 'Paging', Z => 'Zombie', I => 'Sleep');
		} else {#} elsif ($^O =~ /^(linux|solaris)$/)
			$cmd .= ' -eo pid,s';
			%keys = (D => 'IO_Wait', R => 'Run', S => 'Sleep', T => 'Stopped',
					W => 'Paging', X => 'Dead', Z => 'Zombie');
		}

		my $known_keys = join('',keys %keys);
		open(PH,'-|',$cmd) || die "Unable to open file handle PH for command '$cmd': $!\n";
		while (local $_ = <PH>) {
			if (my ($pid,$state) = $_ =~ /^\s*(\d+)\s+(\S+)\s*$/) {
				$state =~ s/[^$known_keys]//g;
				$update{$keys{$state}||$state}++ if $state;
			}
		}
		close(PH) || die "Unable to close file handle PH for command '$cmd': $!\n";
		$update{$_} ||= 0 for values %keys;

	} else {
		eval "use Proc::ProcessTable";
		die "Please install /bin/ps or Proc::ProcessTable\n" if $@;
		my $p = new Proc::ProcessTable("cache_ttys" => 1 );
		for (@{$p->table}) {
			$update{$_->{state}}++;
		}
	}

	return %update;
}



sub cpu_loadavg {
	my %update = ();
	if ($opt{s}) {
		$update{'1min'} = _snmp('.1.3.6.1.4.1.2021.10.1.3.1');
		$update{'5min'} = _snmp('.1.3.6.1.4.1.2021.10.1.3.2');
		$update{'15min'} = _snmp('.1.3.6.1.4.1.2021.10.1.3.3');
		return %update;
	}

	my @data = ();
	if (-f '/proc/loadavg') {
		open(FH,'<','/proc/loadavg') || die "Unable to open file handle FH for file '/proc/loadavg': $!\n";
		my $str = <FH>;
		close(FH) || die "Unable to close file handle FH for file '/proc/loadavg': $!\n";
		@data = split(/\s+/,$str);

	} else {
		my $cmd = -f '/usr/bin/uptime' ? '/usr/bin/uptime' : '/bin/uptime';
		@data = `$cmd` =~ /[\s:]+([\d\.]+)[,\s]+([\d\.]+)[,\s]+([\d\.]+)\s*$/;
	}

	%update = (
		"1min"  => $data[0],
		"5min"  => $data[1],
		"15min" => $data[2],
		);

	return %update;
}



sub _parse_netstat {
	my $cmd = shift;
	my $update;
	my @keys = qw(local_ip local_port remote_ip remote_port);

	if (exists $update_cache{netstat}) {
		$update = $update_cache{netstat};
	} else {
		open(PH,'-|',$cmd) || die "Unable to open file handle for command '$cmd': $!\n";
		while (local $_ = <PH>) {
			my %line;
			if (@line{qw(proto data state)} = $_ =~ /^(tcp[46]?|udp[46]?|raw)\s+(.+)\s+([A-Z_]+)\s*$/) {
				@line{@keys} = $line{data} =~ /(?:^|[\s\b])([:abcdef0-9\.]+):(\d{1,5})(?:[\s\b]|$)/g;
				push @{$update}, \%line;
			}
		}
		close(PH) || die "Unable to close file handle PH for command '$cmd': $!\n";
		$update_cache{netstat} = $update;
	}

	return $update;
}



sub net_connections_ports {
	return if $opt{s};
	my $cmd = select_cmd(qw(/bin/netstat /usr/bin/netstat /usr/sbin/netstat));
	return unless -f $cmd;
	$cmd .= ' -na 2>&1';

	my %update = ();
	my %listening_ports;
	for (@{_parse_netstat($cmd)}) {
		if ($_->{state} =~ /listen/i && defined $_->{local_port}) {
			$listening_ports{"$_->{proto}:$_->{local_port}"} = 1;
			$update{"$_->{proto}_$_->{local_port}"} = 0;
		}
	}
	for (@{_parse_netstat($cmd)}) {
		next if !defined $_->{state} || !defined $_->{remote_port};
		$update{"$_->{proto}_$_->{remote_port}"}++ if exists $listening_ports{"$_->{proto}:$_->{remote_port}"};
	}

	return %update;
}



sub net_connections {
	return if $opt{s};
	my $cmd = select_cmd(qw(/bin/netstat /usr/bin/netstat /usr/sbin/netstat));
	return unless -f $cmd;
	$cmd .= ' -na 2>&1';

	my %update = ();
	for (@{_parse_netstat($cmd)}) {
		$update{$_->{state}}++ if defined $_->{state};
	}

	return %update;
}



sub proc_filehandles {
	return if $opt{s};
	return unless -f '/proc/sys/fs/file-nr';
	my %update = ();

	open(FH,'<','/proc/sys/fs/file-nr') || die "Unable to open file handle FH for file '/proc/sys/fs/file-nr': $!\n";
	my $str = <FH>;
	close(FH) || die "Unable to close file handle FH for file '/proc/sys/fs/file-nr': $!\n";
	@update{qw(Allocated Free Maximum)} = split(/\s+/,$str);
	$update{Used} = $update{Allocated} - $update{Free};

	return %update;
}






