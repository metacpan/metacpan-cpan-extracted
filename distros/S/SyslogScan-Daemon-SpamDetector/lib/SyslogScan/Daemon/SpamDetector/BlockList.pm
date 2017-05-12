

package SyslogScan::Daemon::SpamDetector::BlockList;

use strict;
use warnings;
use SyslogScan::Daemon::SpamDetector::Plugin;
use Plugins::SimpleConfig;
use Time::CTime;
use Time::ParseDate;
use Hash::Util qw(lock_keys);
use DBI;
require POSIX;
our(@ISA) = qw(SyslogScan::Daemon::SpamDetector::Plugin);

my $timefmt = "%Y-%m-%d %T";

my %defaults = (
	debug		=> 1,
	minblock	=> 0.04, # days
	maxblock	=> 1.0,  # days
	blockmult	=> 1.2,
	growtime	=> 0.04,  # < days
	shrinktime	=> 0.25,  # > days
	firstblock	=> 10,
	dbi_dsn		=> 'DBI:mysql:database=xxxxxxx;host=localhost',  # both
	dbi_user	=> 'user',
	dbi_pass	=> 'password',
	block_dbi_dsn	=> 'DBI:mysql:database=xxxxxxx;host=localhost',  # small table
	block_dbi_user	=> 'user',
	block_dbi_pass	=> 'password',
	track_dbi_dsn	=> 'DBI:mysql:database=xxxxxxx;host=localhost',	 # big table
	track_dbi_user	=> 'user',
	track_dbi_pass	=> 'password',
	cleanup		=> 86400/2,
	blockmemory	=> 4,   # days
	spammemory	=> 10,  # days
	blockcommand	=> '',
	recipweight	=> .333333333333333333,
	repeatblocks	=> 20,
	repeatoffender	=> 250,
	rpmult		=> 4,
	fastspammer	=> 10,
	fastspammermult	=> 2,
	cleanupfirst	=> 1,
);

sub config_prefix { 'sdblocklist_' }

sub parse_config_line { simple_config_line(\%defaults, @_); }

sub new 
{
	my $self = simple_new(\%defaults, @_); 
	$self->block_dbh;
	$self->track_dbh;
	$self->{lastclean} = 0;
	$self->{plugins} = undef;
	$self->{block_dbh} ||= undef;
	$self->{track_dbh} ||= undef;
	$self->{lastclean} = time
		unless $self->{cleanupfirst};
	lock_keys(%$self);
	return $self;
}

sub block_dbh
{
	my $self = shift;
	$self->dbh('block');
}
sub track_dbh
{
	my $self = shift;
	$self->dbh('track', AutoCommit => 1);
}

sub dbh
{
	my ($self, $type, %xtra) = @_;
	my $key = $type . "_dbh";
	eval {
		my $old = $self->{$key};
		delete $self->{$key};
		$old->disconnect() if $old;
		$self->{$key} = DBI->connect(
			$self->{"${type}_dbi_dsn"} || $self->{dbi_dsn}, 
			$self->{"${type}_dbi_user"} || $self->{dbi_user}, 
			$self->{"${type}_dbi_pass"} || $self->{dbi_pass},
			{ RaiseError => 1, PrintError => 1, %xtra });
	};
	if ($self->{$key}) {
		print "# opened $type database connection\n" if $self->{debug};
	} else {
		print STDERR "Could not open $type database: $@";
	}
	return $self->{$key};
}

sub reconfig
{
	my $self = shift;
	$self->block_dbh;
	$self->track_dbh;
}

sub mktime 
{
	my ($time) = @_;
	return strftime($timefmt, gmtime($time));
}

sub periodic
{
	my $self = shift;
	my $time = time;
	my $oldblock = $time - 86400 * $self->{blockmemory};
	if ($self->{lastclean} + $self->{cleanup} < time) {
		eval {
			my $block_dbh = $self->{block_dbh};
			$block_dbh->disconnect();
			$self->track_dbh;
			my $track_dbh = $self->{track_dbh};
			$track_dbh->disconnect();
			my $pid = fork();
			if (defined $pid and $pid == 0) {
				eval {
					my $dbh = $self->block_dbh;
					$dbh->begin_work;
					my $c3 = $dbh->do(<<END, undef, mktime($oldblock));
						DELETE FROM block_history
						WHERE  blockend < ?;
END
					$dbh->commit();
					print "# CLEARED $c3 OLD BLOCK HISTORIES\n";
				};
				print STDERR $@ if $@;

				eval {
					print "# Attempting to clear old spam reports\n";
					my $dbh = $self->track_dbh;
					$dbh->begin_work;
					my $oldspam = $time - 86400 * $self->{spammemory};
					my $c4 = $dbh->do(<<END, undef, mktime($oldspam));
						DELETE FROM spam_received
						WHERE  spamtime < ?;
END
					$dbh->commit();
					print "# CLEARED $c4 OLD SPAM REPORTS\n";
				};
				print STDERR $@ if $@;
				POSIX::_exit(0);
			}
		};
		$self->block_dbh;
		$self->track_dbh;
		$self->{lastclean} = time;
	}
}

sub spam_found
{
	my ($self, %info) = @_;
	my $ip = $info{ip};
	my $msgid = $info{hideid} 
		? "redacted"
		: ($info{id}
			? $info{id}
			: "?");

	eval {
		my $time = time;
		my $track_dbh = $self->{track_dbh};
		if ($info{id}) {
			my $idthereq = $track_dbh->prepare_cached(<<END);
				SELECT	COUNT(*)
				FROM    spam_received
				WHERE	ip = ?
				  AND	messageid = ?
END
			$idthereq->execute($ip, $info{id});
			my $crr = $idthereq->fetchall_arrayref();
			$idthereq->finish();
			my $count = $crr->[0][0];
			if ($count) {
				my $morespamq = $track_dbh->prepare_cached(<<END);
					UPDATE	spam_received
					   SET	recipients = recipients + 1,
						spamtime = ?,
						score = ?,
						matched = ?
					 WHERE	ip = ?
					   AND	messageid = ?
END
				$morespamq->execute(mktime($time), $info{score} || "?", $info{match} || "?", $ip, $info{id});
				$morespamq->finish();
			} else {
				my $spamtimeq = $track_dbh->prepare_cached(<<END);
					INSERT INTO spam_received
					VALUES (?, ?, ?, ?, ?, ?, ?)
END
				$spamtimeq->execute($ip, mktime($time), $info{id}, 1, $info{host} || "?", $info{score} || "?", $info{match} || "?") or die $track_dbh->errstr;
				$spamtimeq->finish();
			}
		} else {
			my $spamtimeq = $track_dbh->prepare_cached(<<END);
				INSERT INTO spam_received
				VALUES (?, ?, ?, ?, ?, ?, ?)
END
			$spamtimeq->execute($ip, mktime($time), $info{match} || "?", 1, $info{host} || "?", $info{score} || "?", $info{match} || "?") or die $track_dbh->errstr;
			$spamtimeq->finish();
		}
		my $spamcountq = $track_dbh->prepare_cached(<<END);
			SELECT COUNT(*), SUM(recipients), MIN(spamtime)
			FROM   spam_received
			WHERE  ip = ?
			  AND  spamtime > ?
END
		$spamcountq->execute($ip, mktime($time - 86400 * $self->{spammemory}));
		my $crr = $spamcountq->fetchall_arrayref();
		$spamcountq->finish();
		my $rows = $crr->[0][0];
		my $count = $crr->[0][1];
		my $mintime = parsedate($crr->[0][2], GMT => 1);
		my $days = int(($time - $mintime)/86400) + 1;
		my $weighted = ($count - $rows) * $self->{recipweight} + $rows;
		print STDERR "This is spam # $rows for $ip (recipients = $count, weighted = $weighted)\n" if $self->{debug};
		my $docommand = 0;
		if ($weighted >= $self->{firstblock}) {
			my $block_dbh = $self->{block_dbh};
			print "Blocking $ip due to excessive ($count) spams....\n" if $self->{debug};
				
			$block_dbh->begin_work;
			my $blockstateq = $block_dbh->prepare_cached(<<END);
				SELECT blockstart, blockend, spamcount, blockcount
				FROM   block_history
				WHERE  ip = ?
END
			$blockstateq->execute($ip);
			my $bsrr = $blockstateq->fetchall_arrayref();
			$blockstateq->finish();
			if (@$bsrr) {
				my ($starts, $ends, $oldspamcount, $blockcount) = @{$bsrr->[0]};
				my $end = parsedate($ends, GMT => 1);
				my $start = parsedate($starts, GMT => 1);
				print "START=$start/$starts END=$end/$ends (".mktime($end)."/".strftime("%c", localtime($end)).")\n" if $self->{debug} > 3;
				if ($end > $time) {
					print "... Already blocking $ip\n" if $self->{debug};
				} else {
					my $rpmult = 1;
					if ($self->{repeatoffender} && $weighted > $self->{repeatoffender}) {
						print "Repeat offender penealty (too many spams)\n" if $self->{debug} > 2;
						$rpmult = $self->{rpmult};
					} elsif ($self->{repeatblocks} && $blockcount > $self->{repeatblocks}) {
						print "Repeat offender penealty (blocked too often)\n" if $self->{debug} > 2;
						$rpmult = $self->{rpmult};
					}
					my $oldsize = $end - $start;
					print "OLD BLOCKSIZE = $oldsize\n" if $self->{debug} > 3;
					my $now = time;
					my $newsize = $oldsize;
					if ($now - $end < $self->{growtime} * 86400 * $rpmult) {
						$newsize = $oldsize * $self->{blockmult};
					} elsif ($now - $end > $self->{shrinktime} * 86400 * $rpmult) {
						$newsize = $oldsize / $self->{blockmult};
					}
					if ($weighted - $oldspamcount > $self->{fastspammer}) {
						printf "spamming while blocked penealty (%d)\n", $weighted - $oldspamcount if $self->{debug} > 2;
						$newsize *= $self->{fastspammermult};
					}
					$newsize = $self->{minblock} * 86400
						if $newsize < $self->{minblock} * 86400;
					$newsize = $self->{maxblock} * 86400
						if $newsize > $self->{maxblock} * 86400;
					$block_dbh->do(<<END, undef, mktime($time), mktime($time + $newsize), int($weighted), $msgid, $days, $ip) or die $block_dbh->errstr;
						UPDATE	block_history
						SET	blockstart = ?,
							blockend = ?,
							blockcount = blockcount + 1,
							spamcount = ?,
							messageid = ?,
							countdays = ?
						WHERE	ip = ?;
END
					print "... Reactivating block on $ip... now $newsize seconds long\n" if $self->{debug};
					$docommand = 1;
				}
			} else {
				$docommand = 1;
				my $blocktime = $self->{minblock} * 86400;
				$block_dbh->do(<<END, undef, $ip, mktime($time), mktime($time + $blocktime), int($weighted), $msgid, $days) or die $block_dbh->errstr;
					INSERT	INTO block_history
					VALUES (?, ?, ?, 1, ?, ?, ?);
END
				printf "Adding a first block for $ip for %.2f hours\n", $blocktime/3600 if $self->{debug};
			}
			$block_dbh->commit();
			if ($docommand && $self->{blockcommand}) {
				my $cmd = SyslogScan::Daemon::SpamDetector::substitute($self->{blockcommand}, %info);
				print "+ $cmd\n" if $self->{debug};
				system($cmd);
			}
		}
	};
	if ($@) {
		print STDERR $@;
		$self->block_dbh;
		$self->block_dbh;
	}
}


1;

=head1 NAME

 SyslogScan::Daemon::SpamDetector::BlockList - maintain an IP-based blocklist of spam sources

=head1 SYNOPSIS

 plugin SyslogScan::Daemon::SpamDetector as sd_

 sd_plugin SyslogScan::Daemon::SpamDetector::BlockList
	debug           3
	track_dbi_dsn   'DBI:mysql:database=mailstats;host=localhost'
	track_dbi_user  'username'
	track_dbi_pass  'passwd'
	block_dbi_dsn   'DBI:mysql:database=iimaildb;host=blockhost'
	block_dbi_user  'username'
	block_dbi_pass  'passwd'
	minblock        0.0416666666666667      # minimum block length (days)
	maxblock        1.0     # maximum block length (days)
	blockmult       1.2     # amount to grow/shrink the block
	shrinktime      0.25    # grow the block length if spammed again in less than this (days)
	growtime        0.04    # amount of times w/o a spam to shrink block length (days)
	firstblock      10      # number of spams required to trigger first blocking
	cleanup         86400   # clean up tables, remove blocks (seconds)
	blockmemory     8       # keep history of previous blocks (days)
	spammemory      8       # keep history of spams sent (days)
	recipweight     .33333333333333  # how much does an extra recipient count towards being enough spam to block
	blockcommand    ''
	repeatblocks    50      # times blocked to get worse treatment
	repeatoffender  250     # count of spams to get worse treatment
	rpmult          4       # how much more/less time repeat offenders get to grow shrink their block time
	fastspammer     20      # number of spams sent while blocked to get penealty
	fastspammermult 1.5     # blocktime multipe for fastspammers

=head1 DESCRIPTION

Track and react to the spam noticed by L<SyslogScan::Daemon::SpamDetector>. 

Track the spam in an SQL database.  Build a blocklist.

Block hosts for a bit.  If they keep spamming, block them for longer periods.

We reccomend that this module I<not> be combined with
L<SyslogScan::Daemon::SpamDetector::SpamAssassin> becuase it will end
up blocking forwarded mail.

=head1 CONFIGURATION PARAMETERS

The following configuration parameters are supported:

=over 4

=item debug

Debugging 0 (off) to 5 (verbose).

=item minblock

The minimum amount of time to block an IP address in days.  (Default: about an hour)

=item maxblock

The maximum amount of time to block an IP address in days.  (Default: 1)

=item blockmult

If a site is being re-blocked within the C<growtime> window, multiply the block
time by this amount.  If a site is being re-blocked outside of the C<shrinktime>
window then divide the block time by this amount.  (Default: 1.2)

=item growtime

If a site sends more spam and thus needs re-blocking, punish with a longer block
if it's needing re-blocking before this amount of time has passed.   In days.
(Default: about one hour)

=item shrinktime

If a site sends more spam and thus needs re-blocking but it has been longer 
than this amount of time since it was last blocked, then give it a shorter
block than it had before.  In days.  (Default: .25)

=item firstblock

Don't block a site until this many spam have been recevied.  (Default: 10)

=item block_dbi_dsn
=item block_dbi_user
=item block_dbi_pass

Use this database for the IP block list.  The table is small.

=item track_dbi_dsn
=item track_dbi_user
=item track_dbi_pass

Use this database for tracking incoming spam.  The table is large.

=item cleanup

Perform cleanup of old on the database this often.  Seconds.  (Default: 43200 - 12 hours)

=item blockmemory

Remember inactive blocks for this long.  Days.  (Default: 4).

=item spammemory

Remember incoming spam for this long.  Days.  (Default: 10).

=item blockcommand

Run this command when a block is created.  (No default)

=item recipweight

When the same message is sent to multiple recipients, count the subsequent
deliveries as this much of a spam.  (Default: .333333333333)

=item repeatblocks

When an IP address has been been blocked this man times treat it specially:
instead of multiplying block times by C<blockmult>, multiply them by C<rpmult>.

=item repeatoffender

When an IP address has sent this many spams, treat it specially:
instead of multiplying block times by C<blockmult>, multiply them by C<rpmult>.

=item rpmult

For espeically bad sources,
instead of multiplying block times by C<blockmult>, multiply them by C<rpmult>.
(Default: 4)

=item fastspammer

If this many spams are sent while being blocked (presumably because the block
doesn't cover the entire network), then multiply the block time by 
C<fastspammermult>.

=item fastspammermult

Block multiplier penealty for fast spammers.  (Default: 1.5)

=item cleanupfirst

Clean out old entries from the database tables at startup?  (Default: 1)

=back

=head1 TABLE CREATION

SQL tables are not automatically created.  Here are examples for Mysql5:

 CREATE TABLE spam_received (
	ip		VARCHAR(16),
	spamtime	DATETIME,
	messageid	TEXT,
	recipients	INT,
	host		TEXT,
	score		TEXT,
	matched		TEXT,
	INDEX		ip_index(ip)
 ) TYPE=MyISAM;

 CREATE TABLE block_history (
	ip		VARCHAR(16),
	blockstart	DATETIME,
	blockend	DATETIME,
	blockcount	INT,
	spamcount	INT,
	messageid	TEXT,
	countdays	INT,
	PRIMARY KEY	(ip),
	INDEX		done(blockend)
 ) TYPE=MyISAM;

Replace "Los Angeles" with a city in your time zone.

 drop view blocking;
 CREATE VIEW blocking AS
 SELECT ip, 
	CONCAT("450 blocked for ", 
	SUBTIME(TIMEDIFF(blockend,blockstart),
		SEC_TO_TIME(SECOND(TIMEDIFF(blockend,blockstart)))),
	" until ", ADDTIME(blockend, timediff(now(), utc_timestamp())),
	"-Los Angeles time due to ", spamcount, " spams in ", countdays, 
	" days, for example <", messageid, ">") AS message,
	SUBTIME(TIMEDIFF(blockend,blockstart),
		SEC_TO_TIME(SECOND(TIMEDIFF(blockend,blockstart)))) AS blocktime,
	case when blockend > utc_timestamp() then 1 else 0 end AS active,
	ADDTIME(blockend, timediff(now(), utc_timestamp())) as blockend_local,
	spamcount
 FROM	block_history;

=head1 USEFUL QUERIES

To watch what's going on with the block list, the following queries are
helpful.

 select ip, COUNT(*), SUM(recipients) from spam_received 
 group by ip order by COUNT(*) desc limit 25;

 select COUNT(*), SUM(recipients) from spam_received;

 select active, count(*), AVG(blocktime), AVG(spamcount), MAX(spamcount)
 from blocking group by active;

 select ip, message from blocking where active = 1 order by spamcount;

 select spamcount, COUNT(*), AVG(blocktime), AVG(spamcount)
 from blocking where active = 1 group by spamcount order by spamcount;

 select blocktime, count(*), MIN(spamcount), AVG(spamcount), MAX(spamcount) 
 from blocking where active = 1 group by blocktime order by blocktime;

 select ip, blocktime, spamcount, active
 from blocking 
 order by spamcount desc
 limit 25;

 select count(*), SUM(active) from blocking where spamcount > 250;

 select truncate(spamcount,-1), COUNT(*), AVG(blocktime), AVG(spamcount)
 from blocking where active = 1 group by truncate(spamcount,-1) order by truncate(spamcount,-1);

=head1 POSTFIX CONFIG

To configure Postfix to block using this block list, include a line like:

 smtpd_client_restrictions = check_client_access mysql:/etc/postfix/mysql_spam_senders.cf

Then include a query in the referenced file:

 hosts = localhost maildb
 dbname = spamdb
 user = dbuser
 password = dbpass
 query = SELECT message FROM blocking WHERE ip = '%s' AND active = 1

If your postfix doesn't have SQL support or you're using a less capable mailer,
you can dump the block list into a file:

 mysql -N -B --host=mx --database=spamdb --user=dbuser \
 -e 'select ip, message from blocking where active = 1' \
 > file

=head1 DNS BLOCKLIST

One way to turn this blocklist into a DNS-based blocklist that
can be used like other blocklists is to use L<rbldnsd(8)>.

Set up a L<SyslogScan::Daemon::Periodic> job to rebuild the
blocklist:

 plugin SyslogScan::Daemon::Periodic 
	debug	1
	period	120
	command	'/usr/local/bin/update_blocklist'

The C<update_blocklist> script I use is:

 #!/bin/sh -e

 SUB=1171308796
 SECONDS=`date +%s`
 SEQN=`expr $SECONDS - $SUB`
 DIR="/var/lib/rbldns"
 ZONE="blocked"

 sed "s/SERIAL/$SEQN/" < $DIR/$ZONE.head > $DIR/$ZONE.new

 mysql -N -B --host=MYDBHOST --database=MYDB --user=MYDBUSER \
   -e 'select	ip, concat(":1:",message) \
       from	blocking where active = 1' \
   | sed 's/:450 /:/' \
   >> $DIR/$ZONE.new

 mv $DIR/$ZONE.new $DIR/$ZONE

The C</var/lib/rbldns/blocked.head> file I use:

 $SOA 1800 ns.idiom.com. muir.idiom.com. SERIAL 300 60 3600 300
 $NS 1800 MYHOSTNAME
 $TTL 120

I start L<rbldnsd(8)> with:

 /usr/sbin/rbldnsd -p /var/run/rbldnsd.pid \
  -r/var/lib/rbldns -4 -bMYIPADDRESS/53 \
  spammers.MYDOMAIN:ip4set:blocked

Then, to use it with L<postfix(1)>, I set up a rbl_reply_maps so that
I can give a temporary failure.

 smtpd_client_restrictions =
  permit_mynetworks,
  reject_unauth_pipelining,
  reject_rbl_client cbl.abuseat.org,
  reject_rbl_client spammers.MYDOMAIN

 rbl_reply_maps = hash:/etc/postfix/rbl_reply_maps

My rbl_rply_maps file:

 cbl.abuseat.org   $rbl_code Service unavailable; $rbl_class [$rbl_what] blocked using $rbl_domain${rbl_reason?; $rbl_reason}
 spammers.MYDOMAIN 450 4.7.1 Service unavailable; $rbl_class [$rbl_what] $rbl_reason

=head1 SEE ALSO

L<SyslogScan::Daemon::SpamDetector>

=head1 THANK THE AUTHOR

Hire the author to do some perl programming on your behalf!

=head1 LICENSE

Copyright(C) 2006 David Muir Sharnoff <muir@idiom.com>. 
This module may be used and distributed on the same terms
as Perl itself.

