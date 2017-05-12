# Copyright(C) 2006 David Muir Sharnoff <muir@idiom.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# This software is available without the GPL: please write if you need
# a non-GPL license.  All submissions of patches must come with a
# copyright grant so that David Sharnoff remains able to change the
# license at will.

package Qpsmtpd::Plugin::Quarantine::Batch;

require Exporter;
use OOPS;
use strict;
use Qpsmtpd::Plugin::Quarantine::Common;
use Qpsmtpd::Plugin::Quarantine::Sendmail;
use Mail::SendVarious;
use Mail::SendVarious qw(make_message $mail_error);
use Scalar::Util qw(refaddr);
use IO::Pipe;
use Time::CTime;

my $mailq_timefmt = "%a %b %d %X";

our @ISA = qw(Exporter);
our @EXPORT = qw(cronjob sendqueued mailq);
our @EXPORT_OK = qw(
	find_oldest_bucket prune_headers 
	prune_recipients generate_recipients 
	prune_senders generate_senders 
	walk_eval
	indent);

my $debug = 0;

my $recipients_deleted = 0;
my $recipients_settings = 0;
my $recipients_count = 0;
my $senders_deleted = 0;
my $senders_count = 0;
my $senders_with_settings = 0;
my $stride = 100;

sub cronjob
{
	my $start = time;

	print "# upgrades?\n";
	upgrade();

	print "# cleaning out messages\n" if $debug;
	my $messages_deleted = 0;
	for(;;) {
		my $done;
		my $del;
		my $diskused = message_store_size();
		transaction(sub {
			my $oops = get_oops();
			my $oldest = find_oldest_bucket($oops);
			if ($oldest and (time - $oldest) / 86400 > $defaults{message_longevity}) {
				printf "# Oldest bucket is dated %s, must prune headers\n", scalar(localtime($oldest)) if $debug;
				$del = prune_headers($oops);
			} elsif ($diskused / 1024000 > $defaults{message_store_size}) {
				printf "# Oldest bucket is dated %s, we're over our disk quote -- must prune headers\n", scalar(localtime($oldest)) if $debug;
				$del = prune_headers($oops);
			} else {
				printf "# Oldest bucket is dated %s, we're done\n", scalar(localtime($oldest)) if $debug;
				$done = 1;
			}
			$oops->commit() if $del;
		});
		$messages_deleted += $del;
		last if $done;
	}

	print "Messages deleted: $messages_deleted\n\n";
	print "\n\n";

	print "# cleaning up recipients...\n" if $debug;
	prune_recipients();
	print "Recipients deleted: $recipients_deleted\n";
	print "Recipients kept: $recipients_count\n";
	print "Recipients with settings: $recipients_settings\n";
	print "\n\n";

	print "# cleaning up senders...\n" if $debug;
	prune_senders();
	print "Senders kept: $senders_count\n";
	print "Senders with settings: $senders_with_settings\n";
	print "Senders deleted: $senders_deleted\n";
	print "\n\n";


	printf "Time for batch run: %d (seconds)\n", time - $start;
}

sub upgrade
{
	transaction(sub {
		{
			print "	Upgrade oops?\n";
			my $oops = OOPS->new(oops_args(), auto_ugprade => 1);
			$oops->commit;
		}
		my $version;
		{
			my $oops = get_oops();
			my $qd = $oops->{quarantine};
			$version = $qd->{version};
		}
		if ($version <= 0.31) {
			my $oops = get_oops();
			my $qd = $oops->{quarantine};
			print "Fixing 3600 hours/day problem\n";

			my $time = time;
			my $b0 = $qd->{buckets};
			my $b0count = 0;
			for my $day (sort { $a <=> $b } keys %{$b0}) {
				print " Remapping ".scalar(gmtime($day*86400))."\n";
				my $b1count = 0;
				my $b1 = $b0->{$day};
				for my $bucket (keys %{$b1}) {
					my $oldtime = $day * 86400 + $bucket * 24;
					print "  Bucket at ".scalar(gmtime($oldtime))."\n";
					my $b2 = $b1->{$bucket};
					my $count = 0;
					for my $header_checksum (keys %$b2) {
						$qd->{buckets3}{int($oldtime / 86400)}{int(($oldtime % 86400) / 3600)}{$header_checksum} = $b2->{$header_checksum};
						$oops->virtual_object($qd->{buckets3}{int($oldtime / 86400)}, 1);
						$oops->virtual_object($qd->{buckets3}{int($oldtime / 86400)}{int(($oldtime % 86400) / 3600)}, 1);
						$count++;
					}
					print "  $count headers moved\n";
					$b1count += $count;
					delete $b1->{$bucket};
				}
				print " $b1count moved\n";
				$b0count += $b1count;
				delete $b0->{$day};
			}
			print "Total moved: $b0count\n";
			$oops->commit();
		}
		if ($version < 0.34) {
			$| = 1;
			transaction(sub {
				my $oops = get_oops();
				print "Counting up message storage space...\n";
				my $qd = $oops->{quarantine};
				$qd->{diskused} = {}
					unless $qd->{diskused};
				bless $qd->{diskused}, 'Quarantine::DiskUsage';
				$oops->virtual_object($qd->{diskused}, 1);
			});

			my $tsize = 0;
			my $tcount = 0;
			my $size;
			my $count;
			my @buf;

			require Qpsmtpd::Plugin::Quarantine;

			walk_eval(
				50,
				sub {
					my $oops = shift;
					return $oops->{quarantine}{bodies};
				},
				sub {
					my ($oops, @bodies) = @_;
					my $size = 0;
					my $count = 0;
					my $qd = $oops->{quarantine};
					for my $bdsum (@bodies) {
						my $pbody = $qd->{bodies}{$bdsum};
						return unless $pbody;
						return if $pbody->{size};
						$pbody->{size} = length($pbody->{body});
						$size += $pbody->{size};
						$count += 1;
						print "." if ($tcount + $count) % 10 == 0;
					}
					$qd->{diskused}{$$ % $defaults{size_storage_array_size}} += $size + $count * $defaults{message_size_overhead};
					$tsize += $size;
					$tcount += $count;
					print "C";
				},
				allatonce => 1,
			);

			printf "\n%d messages using %.1fMB\n", $tcount, $tsize / 1024000;

		}
		if ($version < 0.37) {
			print "Running database fsck\n";
			use OOPS::Fsck;
			$OOPS::Fsck::check_batchsize = 2000;
			fsck(oops_args());
			print "Done with fsck\n";
		}
		if ($version < 0.37) {
			print "Running database GC\n";
			use OOPS::GC;
			$OOPS::GC::too_many_todo = 50_000;
			$OOPS::GC::work_length = 10_000;
			$OOPS::GC::clear_batchsize = 4000;
			$OOPS::GC::virtual_hash_slice = 3_000;
			$OOPS::GC::maximum_spill_size = 10_000;
		}
		update_version();
	});
}

sub update_version
{
	my ($oops) = @_;
	my $doit = sub {
		my $qd = $oops->{quarantine};
		require Qpsmtpd::Plugin::Quarantine;
		$qd->{version} = $Qpsmtpd::Plugin::Quarantine::VERSION;
	};
	if ($oops) {
		&$doit();
	} else {
		transaction(sub {
			$oops = get_oops();
			&$doit();
			$oops->commit;
		});
	}
}

sub find_oldest_bucket
{
	my ($oops) = @_;

	my $qd = $oops->{quarantine};

	my $b0 = $qd->{buckets3};

	my ($b0first) = sort { $a <=> $b } keys %{$b0};
	my $b1 = $b0->{$b0first};
	my ($b1first) = sort { $a <=> $b } keys %{$b1};

	my $bucket = $b1->{$b1first};

	return ($b0, $b0first, $b1, $b1first, $bucket) if wantarray;
	return $b0first * 86400 + $b1first * 3600;
}

sub message_store_size
{
	transaction(sub {
		my $oops = get_oops();
		my $qd = $oops->{quarantine};
		my $size = 0;
		for my $v (values %{$qd->{diskused}}) {
			$size += $v;
		}
printf "Disk space used %.1fMB\n", $size / 1024000;
		return $size;
	});
}

my $mqueue_sent;
my $mqueue_unsent;

sub sendqueued
{
	walk_eval($defaults{mqueue_stride_length}, sub {
		my $oops = shift;
		return $oops->{quarantine}{mqueue};
	}, \&mqueue_agent, allatonce => 1);
}

sub mqueue_agent
{
	my ($oops, @mqueue) = @_;
	for my $mqueue (@mqueue) {
		my $mq = $oops->{mqueue}{$mqueue};
		next unless time - $mq->{last_attempt} >= $defaults{mqueue_minimum_gap};
		$oops->lock($oops->{mqueue}{$mqueue});
	}
	for my $mqueue (@mqueue) {
		my $mq = $oops->{mqueue}{$mqueue};
		next unless time - $mq->{last_attempt} >= $defaults{mqueue_minimum_gap};
		mqueue_agent2($oops, $mqueue);
	}
}

sub mqueue_agent2
{
	my ($oops, $mqueue) = @_;
	my $mq = $oops->{mqueue}{$mqueue} || return;

	if (sendmail(%$mq, debuglogger => sub { 1 }, errorlogger => sub { 1 })) {
		delete $oops->{mqueue}{$mqueue};
		$mqueue_sent++;
		return;
	}
	$mq->{last_attempt} = time;
	$mq->{attempt_count}++;
	$mq->{last_error} = $mail_error;

	if (time - $mq->{first_attempt} >= $mq->{mqueue_maximum_keep} 
		and $mq->{attempt_count} >= $defaults{mqueue_minimum_attempts}) 
	{
		delete $oops->{mqueue}{$mqueue};
		if ($mq->{from} ne "<>" && $mq->{from} ne $defaults{bounce_from} && $mq->{from} =~ /^mailer-daemon\@/i) {
			my (undef, $mes) = make_message(%$mq);
			sendmail_or_postpone(
				from		=> $defaults{bounce_from},
				subject		=> "Returned mail: $mq->{last_error}",
				to		=> $mq->{from},
				body		=> <<END,
We attempted to send a message on your behalf but we could
not do so.  The specific problem we had was:

 $mq->{last_error}

The message we were trying to send was:

$mes
END
				debuglogger	=> sub { 1 },
			);
		}
	}
}

sub mqueue_postcommit
{
	send_postponed();
}

sub mailq
{
	my $oops = get_oops(readonly => 1, less_caching => 1);
	my $qd = $oops->{quarantine};
	my $count = 0;
	my $size = 0;
	for my $mqueue (keys %{$qd->{mqueue}}) {
		my $mq = $qd->{mqueue}{$mqueue};
		my ($from, $message, @to) = make_message(%$mq);
		printf "%15s %6d %20s  %s\n", $mqueue, length($message), strftime($mailq_timefmt, localtime($mq->{first_attempt})), $from;
		print  "    ($mq->{last_error})\n";
		for my $t (@to) {
			print  "\t\t\t\t\t $t\n";
		}
		$count++;
		$size += length($message);
	}
	printf "-- %d Kbytes in %d Requests.\n", $size / 1024, $count;
}

sub prune_headers
{
	my ($oops, $messages) = @_;

	$messages = $defaults{delete_batchsize}
		unless $messages;

	print "Pruning $messages messages\n" if $debug > 2;

	my $qd = $oops->{quarantine};

	my ($b0, $b0first, $b1, $b1first, $bucket);

	for(;;) {
		($b0, $b0first, $b1, $b1first, $bucket) = find_oldest_bucket($oops);
		last if $bucket && %$bucket;
		if (%$b1) {
			print "Deleting b1first $b1first\n" if $debug >2;
			delete $b1->{$b1first};
			redo;
		}
		if (%$b0) {
			print "Deleting b0first $b0first\n" if $debug >2;
			delete $b0->{$b0first};
			redo;
		}
		die "no messages";
	}

	my $pruned = 0;
	my ($hcksum, $pheader);
	while (($hcksum, $pheader) = each(%$bucket)) {
		return --$pruned if $pruned++ >= $messages;

		my $wasdone = $pheader->{done};
		my $pbody = $pheader->{body};
		my $psender = $pheader->{sender};
		my $recipients = $pheader->{recipients};

		print STDERR <<END if $debug > 3;
Removing....
From $psender->{address}
From: $pheader->{from}To: $pheader->{to}Subject: $pheader->{subject}Date: $pheader->{date}
END

		%$pheader = ();

		if (refaddr($pbody->{last_reference}) == refaddr($pheader)) {
			delete $pbody->{last_reference};
			my $bcksum = $pbody->{cksum};
			delete $qd->{bodies}{$bcksum};
			$qd->{diskused}{$$ % $defaults{size_storage_array_size}}
				-= $pbody->{size};

			print STDERR "(body too)\n\n" if $debug > 3
		} else {
			print STDERR "\n" if $debug > 3;
		}
		delete $bucket->{$hcksum};
		delete $qd->{headers}{$hcksum};
		delete $psender->{headers}{$hcksum};
		for my $r (@{$pheader->{recipients}}) {
			my $rd = $qd->{recipients}{$r};
			if ($rd->{headers}{$hcksum}) {
				delete $rd->{headers}{$hcksum};
				$rd->{mcount}-- unless $wasdone;
			}
		}
	}
	print "Only pruned $pruned messages\n" if $debug >2;
	delete $b1->{$b1first};
	return $pruned;
}


sub prune_recipients
{
	walk_eval($defaults{recipent_stride_length}, sub { my $oops = shift; return $oops->{quarantine}{recipients} }, \&recipient_agent);
}

sub recipient_agent
{
	my ($oops, $recipient) = @_;
	my $qd = $oops->{quarantine};
	my $rd = $qd->{recipients}{$recipient};
	unless ($rd) {
		print STDERR "That's odd, cannot find recipient '$recipient'\n";
		delete $qd->{recipients}{$recipient};
		return;
	}
	unless ($rd->{headers}) {
		print STDERR "Recipient $recipient invalid, deleting\n";
		delete $qd->{recipients}{$recipient};
		$recipients_deleted++;
		return;
	}
	my $msgcount = %{$rd->{headers}} ? scalar(%{$rd->{headers}}) : 0;
	print "Recipient: $recipient..." if $debug;
	printf " (has %d messages)", $msgcount if $debug;
	printf " %d days idle...", (time - $rd->{last_timestamp})/86400 if $debug;
	print " has settings" if $debug && $rd->has_settings;
	if (
		(
			(time - $rd->{last_timestamp}) / 86400 > $defaults{keep_idle_recipients} 
			&& 
			! $msgcount
		)
		||
		(
			(time - $rd->{last_timestamp}) / 86400 > $defaults{message_longevity}
			&&
			! $rd->has_settings()
			&&
			! $msgcount
		)
	) {
		delete $qd->{recipients}{$recipient};
		$recipients_deleted++;
		print " DELETE" if $debug;
	} else {
		$recipients_settings++ if $rd->has_settings();
		$recipients_count++;
	}
	print "\n" if $debug;
}

sub prune_senders
{
	walk_eval($defaults{sender_stride_length}, sub { my $oops = shift; return $oops->{quarantine}{senders} }, \&sender_agent);
}

sub sender_agent
{
	my ($oops, $sender) = @_;
	my $qd = $oops->{quarantine};
	my $psender = $qd->{senders}{$sender};
	unless ($psender) {
		print STDERR "That's odd, cannot find sender '$sender'\n";
		delete $qd->{senders}{$sender};
		return;
	}

	print "Sender: $sender" if $debug;


	my ($ip, $tstamp);
	my $kept;
	while (($ip, $tstamp) = each %{$psender->{send_ip_used}}) {
		printf " (from %s %d ago)", $ip, (time - $tstamp)/86400 if $debug;
		if (time - $tstamp > 86400 * $defaults{renotify_sender_ip} * 2) {
			print "[D]" if $debug;
			delete $psender->{send_ip_used}{$ip};
		} else {
			$kept++;
		}
	}

	my $spams_sent;
	my $today = time / 86400;
	my $count = 0;
	for my $spamday (keys %{$psender->{spams_sent_perday}}) {
		if ($today - $spamday > $defaults{sender_history_to_keep}) {
			delete $psender->{spams_sent_perday}{$spamday};
			next;
		}
		$spams_sent += $psender->{spams_sent_perday}{$spamday};
		$count++;
	}
	delete $psender->{spams_sent_perday} unless $spams_sent;
	printf " %d spams in %d days", $spams_sent, $count if $debug;

	if ($spams_sent >= $defaults{report_senders_after}) {
		print "\n" if $debug;
		print "Sender $sender has sent $spams_sent in the last $defaults{sender_history_to_keep} days\n";
		my ($hsum, $pheader);
		while (($hsum, $pheader) = each %{$psender->{headers}}) {
			print "\nFor example:\n";
			indent($pheader->{header});
			indent($pheader->{body}{body}, limit => 100);
			last;
		}
	}

	my $has_settings = $psender->has_settings();

	printf " kept:%d ss/day:%d settings:%d headers:%s", $kept, scalar(%$psender->{spams_sent_perday}), !!$has_settings, scalar(%{$psender->{headers}}) if $debug;

	if (! $kept && ! scalar(%$psender->{spams_sent_perday}) && ! $has_settings && ! scalar(%{$psender->{headers}})) {
		print " DELETE" if $debug;
		delete $qd->{senders}{$sender};
		$senders_deleted++;
	} else {
		$senders_count++;
		$senders_with_settings++ if $has_settings;
	}
	print "\n" if $debug;
}

sub indent
{
	my ($text, %args) = @_;
	my $tab = $args{indent} || "\t";
	my $limit = $args{limit} || 0;
	while (--$limit != 0 && $text =~ /^(.*)/gm) {
		print "$tab$1\n";
	}
}

sub walk_eval
{
	my ($stride, $get_hash, $agent, %opts) = @_;
	my $done = 0;
	my $last = undef;
	$stride ||= 100;
	while (! $done) {
		transaction(sub {
			my $oops = get_oops();
			my $hash = &$get_hash($oops);
			my @items = walk_hash(%$hash, $stride, $last);
			if ($opts{allatonce}) {
				&$agent($oops, @items);
			} else {
				for my $item (@items) {
					&$agent($oops, $item);
				}
			}
			$oops->commit();
			$last = $items[$#items];
			$done = 1 unless @items == $stride;
		});
	}
}

1;
