
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

package Qpsmtpd::Plugin::Quarantine;

use Qpsmtpd::Constants;
use Qpsmtpd::DSN;
use OOPS;
use Digest::MD5 qw(md5_hex);
use File::Slurp;
use Time::HiRes qw();
use Net::Netmask;
use CGI;
use Template;
use Sys::Hostname;
use Mail::SPF::Query;
use Mail::Field;
use Net::SMTP;
use Mail::Address;
use DB_File;
use Qpsmtpd::Plugin::Quarantine::Spam;
use Qpsmtpd::Plugin::Quarantine::Common;
use Qpsmtpd::Plugin::Quarantine::Sendmail;
require Mail::Field::Received;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(hook_data_post register);
@EXPORT_OK = qw($hostname);

use strict;
use warnings;

our $VERSION = 1.02;
my $debug = 1;

our $myhostname = hostname();

my $fmes1 = "Your message is quarantined because we think it is probably spam, if it is not spam, click"; 
my $fmes2 = "to release your message from quarantine or to choose to have the spam you send silently deleted instead of bounced";
my $fmes3 = "None of the recipients of your email wish to receive mail that is likely to be spam";

# -----------------------------------------------------------------------

my $qa = {}; # state hash

my $fmes1rx = $defaults{senderbounce1};
$fmes1rx =~ s/ /\\s+/g;
$fmes1rx = qr/$fmes1rx/;
my $fmes2rx = $defaults{senderbounce2};
$fmes2rx =~ s/ /\\s+/g;
$fmes2rx = qr/$fmes2rx/;
my $fmes3rx = $defaults{senderbounce3};
$fmes3rx =~ s/ /\\s+/g;
$fmes3rx = qr/$fmes3rx/;

# -----------------------------------------------------------------------

sub register
{
	my ($qp, undef, @args) = @_;
	my %args;
	if (@args % 2 == 0) {
		%args = @args;
	} else {
		warn "Malformed arguments to syslog plugin";
		return DECLINED;
	}
	$qa->{justkidding} = "no templates directory"
		unless -d $defaults{templates};
	$qa->{start_time} = Time::HiRes::time();
	$qa->{our_domains} = { map { $_ => 1 } $qp->qp->config('our_domains') };
	$qa->{filter_domains} = { map { $_ => 1 } $qp->qp->config('filter_domains') };

	recompute_defaults;

	if (0 && $debug) {
		for my $i (sort keys %{$qa->{our_domains}}) {
			$qp->log(LOGDEBUG, "Our domain: $i");
		}
		for my $i (sort keys %{$qa->{filter_domains}}) {
			$qp->log(LOGDEBUG, "Filter domain: $i");
		}
	}

	$qa->{our_networks} = {};
	for my $net ($qp->qp->config('our_networks')) {
		my $block = new2 Net::Netmask $net;
		$qp->log(LOGDEBUG, "Our network: $net");
		if ($block) {
			$block->storeNetblock($qa->{our_networks});
		} else {
			warn "Cannot parse network block '$net': $Net::Netmask::error"
		}
	}
	$qa->{ignore_networks} = {};
	for my $net ($qp->qp->config('ignore_networks'), @{$defaults{ignore_networks}}) {
		my $block = new2 Net::Netmask $net;
		$qp->log(LOGDEBUG, "Ingore network: $net");
		if ($block) {
			$block->storeNetblock($qa->{ignore_networks});
		} else {
			warn "Cannot parse network block '$net': $Net::Netmask::error"
		}
	}

	$qa->{template} = Template->new({
		INCLUDE_PATH	=> $args{templates},
		INTERPOLATE	=> 1,
		POST_CHOMP	=> 0,
		EVAL_PERL	=> 1,
		RECURSION	=> 1,
	}) || die Template->error();
	srand(time ^ ($$ << 5));

	if ($defaults{notify_recipient_only} && -e $defaults{notify_recipient_only}) {
		my $db = tie my %h, 'DB_File', $defaults{notify_recipient_only} 
			or die "dbopen $defaults{notify_recipient_only}: $!";
		$db->filter_fetch_key  ( sub { s/\0$//    } ) ;
		$db->filter_store_key  ( sub { $_ .= "\0" } ) ;
		$db->filter_fetch_value( sub { s/\0$//    } ) ;
		$db->filter_store_value( sub { $_ .= "\0" } ) ;

		$qa->{notify_recipient_only} = \%h;
	} else {
		$qa->{notify_recipient_only} = {};
	}

	if ($defaults{special_sender_db} && -e $defaults{special_sender_db}) {
		my $db = tie my %h, 'DB_File', $defaults{special_sender_db}
			or die "dbmopen $defaults{special_sender_db}: $!";
		$db->filter_fetch_key  ( sub { s/\0$//    } ) ;
		$db->filter_store_key  ( sub { $_ .= "\0" } ) ;
		$db->filter_fetch_value( sub { s/\0$//    } ) ;
		$db->filter_store_value( sub { $_ .= "\0" } ) ;

		$qa->{special_sender_db} = \%h;
	} else {
		$qa->{sepcial_sender_db} = {};
	}

	spam_init();

	return OK;
}

sub hook_data_post
{
	my ($qp, $transaction) = @_;

	$qp->log(LOGDEBUG, "----------------------------------------------------------------------------------");

	get_message_info($qp, $transaction);

	if ($transaction->notes('filtered_recipient_count')) {
		$qp->log(LOGDEBUG, "Checking message to a filtered destination");
	} elsif ($defaults{check_from_our_ip} && $transaction->notes('address_type') eq 'internal') {
		$qp->log(LOGDEBUG, "Checking message from our IP addresses");
	} elsif ($defaults{check_not_from_our_ip} && $transaction->notes('address_type') eq 'external') {
		$qp->log(LOGDEBUG, "Checking message not from our IP addresses");
	} elsif ($defaults{check_from_our_domain} && $transaction->notes('from_our_domain')) {
		$qp->log(LOGDEBUG, "Checking message from our domain");
	} elsif ($defaults{check_not_our_domain} && ! $transaction->notes('from_our_domain')) {
		$qp->log(LOGDEBUG, "Checking message not from our domain");
	} elsif ($defaults{check_all_recipients}) {
		$qp->log(LOGDEBUG, "Checking message because we check 'em all");
	} elsif ($defaults{special_sender_db} && $qa->{special_sender_db}{$transaction->sender->address()}) {
		$qp->log(LOGDEBUG, "Checking message from a special sender");
	} elsif ($defaults{randomly_check_messages} && rand(100) < $defaults{randomly_check_messages}) {
		$qp->log(LOGDEBUG, "Checking message randomly");
	} else {
		$qp->log(LOGDEBUG, "QRESULT: Not checking for spam");
		return DECLINED;
	}

	my $spammy = check_message_for_spam($qp, $transaction);

	unless ($spammy) {
		$qp->log(LOGDEBUG, "QRESULT: Not spam");
		return DECLINED;
	}

	return filterit($qp, $transaction, $spammy);
}

sub filterit
{
	my ($qp, $transaction, $spam_reason) = @_;
	my @retcode = DECLINED;
	die unless $qa->{our_networks};
	my $qt = $transaction->notes('quarantine');
	if ($qa->{justkidding}) {
		$qp->log(LOGDEBUG, "skipping... $qa->{justkidding}");
		return DECLINED;
	}
	if ($qt->{already_filtered}++) {
		$qp->log(LOGDEBUG, "skipping... already filtered");
		return DECLINED;
	}

	my $body = $transaction->body_as_string();
	my $body_checksum = md5_hex($body);
	my $headers = $transaction->header();
	my $header = $headers->as_string();
	my $suser = $transaction->sender->user();
	my $sdomain = $transaction->sender->host();
	my $sender_address = "$suser\@$sdomain";
	my @recipients = map { $_->address() } $transaction->recipients();

	my $ip = $transaction->notes('external_ip') || $transaction->notes('internal_ip');


	transaction(sub {
		my $oops = get_oops();
		my $time = time;
		my $qd = $oops->{quarantine} || initialize($qp, $oops, $transaction);
		my $psender = $qd->{senders}{$sender_address};
		my $sender_token = $psender 
			? $psender->{token}
			: md5_hex($$ . Time::HiRes::time() . $sender_address);
		my $header_checksum = md5_hex($header . $qd->{random_token} . $sender_token);

		#
		# Let our own bounces through (up to a point)
		#

		$qp->log(LOGDEBUG, "RX: $fmes1rx\\s+\Q$defaults{baseurl}\E/message/(\\S+)\\s+$fmes2rx");
		if ($body =~ m{$fmes1rx\s+\Q$defaults{baseurl}\E/message/(\S+)\s+$fmes2rx}s && exists $qd->{headers}{$1}) {

			# This is an email about something we have held in quarantine.
			my $pheader = $qd->{headers}{$1};
			if ($pheader->{bounce_seen}++ < $defaults{max_bounces_per_header}) {
				$oops->commit();
				$qp->log(LOGINFO, "QRESULT: Message with our own bounce forwarded");
				@retcode = DECLINED;
				return;
			} else {
				$qp->log(LOGINFO, "No free pass for our own bounce, this is number $pheader->{bounce_seen} for this message");
			}
		}
		$qp->log(LOGDEBUG, "RX MATCHED ($1)") if $1;

		#
		# Check to see if any of the recipients have set options to control
		# their mail.
		#

		my $recipients_modified = 0;
		my (@nr);
		my $counter = 0;
		my %remap_from;
		for my $r (@recipients) {
			my $rd;
			if (($rd = $qd->{recipients}{$r}) && $rd->{action}) {
				if ($rd->{action} eq 'drop') {
					$qp->log(LOGDEBUG, "Recipient '$r': drop");
					# skip this one...
				} elsif ($rd->{action} eq 'forward' && $counter < 10) {
					my ($nap) = Mail::Address->parse($rd->{new_address});
					if ($nap && $nap->address) {
						$qp->log(LOGDEBUG, "Recipient '$r': redirect to ".$nap->address);
						$remap_from{$nap->address} = $r;
						$r = $nap->address;
						$counter++;
						redo;
					} else {
						$qp->log(LOGWARN, "Could not parse forward address for $r: '$rd->{new_address}'");
						push(@nr, $r);
					}
				} else {
					$qp->log(LOGWARN, "Bogus action for $r: '$rd->{action}'");
					push(@nr, $r);
				}
			} else {
				$qp->log(LOGDEBUG, "No special action for recipient '$r'");
				push(@nr, $r);
			}
			$counter = 0;
		}
		@recipients = @nr;

		#
		# Let's figure out which recipients get notified, which get protected,
		# and which get a message.
		#

		my @passthrough_recipients;	# not quarantined
		my @quarantine_recipients;	# quarantined and they know it
		my @filter_recipients;		# quarantined but they don't know it 
		my @queued_messages;
		for my $r (@recipients) {
			my $rd = $qd->{recipients}{$r};
			my ($ra) = Mail::Address->parse($r);
			die unless ref($ra);
			my $rdomain = $ra->host;
			if (! $rd && ! match_domain($qp, $rdomain, $qa->{filter_domains}, 'filter_domains')) {
				push(@passthrough_recipients, $r);
				next;
			}
			$rd = new_recipient($oops, $r)
				unless $rd;
			$rd->{mcount} += 1;
			$rd->{total_count} += 1;

			my $do_qr = 0;
			if ($rd->{total_count} >= $defaults{notify_recipients}) {
				$do_qr = "Recipient $r has is over the threshold ($rd->{total_count}): let the recipient choose";
			} else {
				$qp->log(LOGDEBUG, "Recipient $r is under the threshold ($rd->{total_count})");
			}
			if (! $do_qr and $qa->{notify_recipient_only}{lc($r)}) {
				$do_qr = "Recipient is in the special list: let the recipient choose";
			} else {
				$qp->log(LOGDEBUG, "Lookup of notify_recipient_only{$r} = nada");
			}
			if ($do_qr) {
				$qp->log(LOGDEBUG, $do_qr);
				if ($time - $rd->{last_timestamp} > 86400 * $defaults{renotify_recipient_days}) {
					push(@queued_messages, send_recipient_notification($qp, $transaction, $r, $rd, $qd))
				} else {
					$qp->log(LOGDEBUG, "Not yet time to bug recipient $r");
				}
				push(@quarantine_recipients, $r);
			} else {
				push(@filter_recipients, $r);
			}
			$rd->{last_timestamp} = $time;
		}

		if (@passthrough_recipients == 1 && @quarantine_recipients == 0 && @filter_recipients == 0 && $remap_from{$passthrough_recipients[0]}) {
			$headers->replace('X-Mail-Redirected-From', "$remap_from{$passthrough_recipients[0]} on $myhostname");
			$transaction->header($headers);
		}

		my $notify_recipients_only = @quarantine_recipients && ! @filter_recipients;

		#
		# Basic sender tracking
		#

		$psender = new_sender($oops, $sender_address, $transaction->sender->address(), $sender_token)
			unless $psender;
		my $sender_ip_last_used = $psender->{send_ip_used}{$ip} || 0;

		#
		# What are we doing?
		#

		my $reply = '';
		my $noteOK = '';
		my $noteDENY = '';

		my $sender_okay = 
			(
				spf($qp, $transaction) eq 'pass' 
				&&
				($noteOK = 'sender-SPF-passed')
			)
			|| 
			(
				(
					(
						$transaction->notes('origin_type') eq 'internal'
						&&
						($noteOK = 'from-one-of-our-ip-addresses')
					)
					||
					(
						$transaction->notes('from_our_domain') 
						&&
						($noteOK = 'from-one-of-our-domains')
					)
				)
				&& 
				! (
					spf($qp, $transaction) eq 'fail' 
					&&
					($noteDENY = 'sender-SPF-failed')
				)
			)
			||
			(
				(
					$defaults{notify_other_senders}
					&&
					($noteOK = 'notify-external-senders')
				)
				&& 
				! (
					spf($qp, $transaction) eq 'fail' 
					&&
					($noteDENY = 'sender-SPF-failed')
				)
			)
		;

		my $no_recipient_bounce_body =
			! @recipients
			&&
			$body =~ m{$fmes3rx}
			&&
			($reply = 'message will be discarded as useless bounce')
		;

		my $sender_bounce = $sender_okay; 
		$sender_bounce = 0
			if
				( 
					$transaction->sender() eq "<>"
					&&
					($reply = 'no bounces for MAILER-DAEMON')
				)
				||
				( 
					$psender->{action} 
					&& 
					$psender->{action} eq 'discard' 
					&&
					($reply = "sender doesn't want to know")
				)
				||
				( 	
					$notify_recipients_only 
					&& 
					($reply = 'recipients will be notified instead')
				)
				||
				$no_recipient_bounce_body 
			;

		my $sender_quarantine = $sender_bounce;
		$sender_quarantine = 0 
			if 
				(
					$psender->{action} 
					&& 
					$psender->{action} eq 'bounce' 
					&&
					($reply = "Bounced due to your request at $defaults{baseurl}")
				)
				||
				( 
					! @recipients
					&&
					($reply = 'No Recipients Want Spammy Messages')
				)
			;


		my $do_quarantine = 
			(
				(
					$sender_quarantine
					&&
					@filter_recipients
				)
				||
				@quarantine_recipients
			)
		;

		$sender_bounce = 0
			if
				( 
					$sender_bounce
					&&
					$time - $sender_ip_last_used < 86400 * ($psender->{renotify_days} || $defaults{renotify_sender_ip})
					&&
					($reply = 'not yet time for another bounce')
				)
			;

		#
		# Sender tracking.   Track how many spams are sent and save one every now and then.
		#

		if ($sender_bounce) {
			$psender->{send_ip_used}{$ip} = $time;
		}
		my $today = $time / 86400;
		my $spams_sent = 0;
		$psender->{spams_sent_perday}{$today} += 1;
		for my $spamday ($psender->{spams_sent_perday}) {
			next if $today - $spamday > $defaults{sender_history_to_keep};
			$spams_sent += $psender->{spams_sent_perday};
		}
		if ($defaults{keep_every_nth_message} && ($spams_sent % $defaults{keep_every_nth_message}) == 0) {
			$do_quarantine = 1;
		}
		$psender->{last_message} = $time;

		#
		# We only need to save the message if it's interesting.
		#
		if ($do_quarantine) {
			my $pbody = $qd->{bodies}{$body_checksum};
			unless ($pbody) {
				$pbody = $qd->{bodies}{$body_checksum} = bless {
					body 	=> $body,
					cksum	=> $body_checksum,
					size	=> length($body),
				}, 'Quarantine::Body';
				$qd->{diskused}{$$ % $defaults{size_storage_array_size}}
					+= length($body) + $defaults{message_size_overhead};
			}
			my @recip = $sender_quarantine
				? @recipients
				: (@filter_recipients, @quarantine_recipients);

			my $pheader = $qd->{headers}{$header_checksum} = bless {
				from	=> $headers->get('From'),
				to	=> $headers->get('To'),
				subject	=> $headers->get('Subject'),
				date	=> $headers->get('Date'),
				time	=> $time,
				sender	=> $psender,
				recipients => (bless [ @recip ], 'Quarantine::RecipientList'),
				header	=> $header,
				body	=> $pbody,
				cksum	=> $header_checksum,
			}, 'Quarantine::Header';
			$pbody->{last_reference} = $pheader;
			$psender->{headers}{$header_checksum} = $pheader;
			unless ($qd->{buckets3}) {
				$qd->{buckets3} = bless {}, 'Quarantine::Buckets';
			}
			$qd->{buckets3}{int($time / 86400)}{int(($time % 86400) / 3600)}{$header_checksum} = $pheader;
			$oops->virtual_object($qd->{buckets3}{int($time / 86400)}, 1);
			$oops->virtual_object($qd->{buckets3}{int($time / 86400)}{int(($time % 86400) / 3600)}, 1);

			for my $r (@quarantine_recipients, @filter_recipients) {
				my $rd = $qd->{recipients}{$r};
				$rd->{headers}{$header_checksum} = $pheader;
			}
		}

		#
		# Some debugging
		#

		$qp->log(LOGDEBUG, "recipients = @recipients");
		$qp->log(LOGDEBUG, "filter_recipients = @filter_recipients");
		$qp->log(LOGDEBUG, "quarantine_recipients = @quarantine_recipients");
		$qp->log(LOGDEBUG, "passthrough_recipients = @passthrough_recipients");
		$qp->log(LOGDEBUG, "notify_recipients_only = $notify_recipients_only");
		$qp->log(LOGDEBUG, "reply = $reply");
		$qp->log(LOGDEBUG, "noteOK = $noteOK");
		$qp->log(LOGDEBUG, "noteDENY = $noteDENY");
		$qp->log(LOGDEBUG, "sender_okay = $sender_okay");
		$qp->log(LOGDEBUG, "no_recipient_bounce_body = $no_recipient_bounce_body");
		$qp->log(LOGDEBUG, "sender_bounce = $sender_bounce");
		$qp->log(LOGDEBUG, "sender_quarantine = $sender_quarantine");
		$qp->log(LOGDEBUG, "do_quarantine = $do_quarantine");

		#
		# Do it.
		#

		$oops->commit();

		my $messageid = $headers->get('Message-ID');
		$messageid =~ s/[\r\n]+\z//;

		my (@new_recip);
		for my $r (@passthrough_recipients) {
			push(@new_recip, Qpsmtpd::Address->new($r));
		}
		@new_recip = Qpsmtpd::Address->new($defaults{nobody_address})
			unless @new_recip;

		if ($do_quarantine && $sender_quarantine) {
			my $and_recipients = @queued_messages ? ", Recipients Notified" : "";
			$qp->log(LOGINFO, "QRESULT: Message quarantined, sender notified$and_recipients - $noteOK - $messageid");
			@retcode = Qpsmtpd::DSN->mbox_disabled(DENY, "$fmes1 $defaults{baseurl}/message/$header_checksum $fmes2");
		} elsif ($sender_bounce && ! @recipients) {
			$qp->log(LOGINFO, "QRESULT: Message bounced - no recipients - $noteOK - $messageid");
			@retcode = Qpsmtpd::DSN->mbox_disabled(DENY, $defaults{senderbounce3});
		} elsif ($do_quarantine && @quarantine_recipients && @passthrough_recipients) {
			$qp->log(LOGINFO, "QRESULT: Message quarantined silently; some recipients notified, some passthrough - $noteOK $noteDENY - $messageid");
			$transaction->recipients(@new_recip);
			@retcode = DECLINED;
		} elsif ($do_quarantine && @quarantine_recipients) {
			$qp->log(LOGINFO, "QRESULT: Message quarantined silently, recipients notified - $noteOK $noteDENY - $messageid");
			$transaction->recipients(@new_recip);
			@retcode = DECLINED;
		} elsif ($do_quarantine && @passthrough_recipients) {
			# is this possible?
			$qp->log(LOGINFO, "QRESULT: Message quarantined silently, some recipients passthrough $noteOK $noteDENY - $messageid");
			$transaction->recipients(@new_recip);
			@retcode = DECLINED;
		} elsif ($do_quarantine) {
			# is this possible?
			$qp->log(LOGINFO, "QRESULT: Message quarantined silently $noteOK $noteDENY - $messageid");
			$transaction->recipients(@new_recip);
			@retcode = DECLINED;
		} elsif (@passthrough_recipients && ! @filter_recipients && ! @quarantine_recipients) {
			$qp->log(LOGINFO, "QRESULT: Messages allowed $noteOK $noteDENY - $messageid");
			$transaction->recipients(@new_recip);
			@retcode = DECLINED;
		} elsif ($sender_bounce) {
			# 
			# it doesn't matter if there were some passthrough recipients, we're 
			# bouncing it back to the sender 'cause it looked spammy.
			#
			$qp->log(LOGINFO, "QRESULT: Message bounced $reply - $noteOK - $messageid");
			@retcode = Qpsmtpd::DSN->mbox_disabled(DENY, $reply || "Spammy message rejected.  See $defaults{baseurl} for options");
		} elsif (@passthrough_recipients) {
			$qp->log(LOGINFO, "QRESULT: Message passed through $noteOK $noteDENY - $messageid");
			$transaction->recipients(@new_recip);
			@retcode = DECLINED;
		} else {
			$qp->log(LOGINFO, "QRESULT: Message discarded silently $reply $noteOK $noteDENY - $messageid");
			$transaction->recipients(Qpsmtpd::Address->new($defaults{nobody_address}));
			@retcode = DECLINED;
		}

		if ($do_quarantine) {
			for my $qm (@queued_messages) {
				$qp->log(LOGDEBUG, "Sending message to $qm->{recipient}:\n$qm->{message}");
				sendmail_or_queue(
					from => $defaults{send_from}, 
					to => $qm->{recipient}, 
					message => $qm->{message}, 
					debuglogger => sub { $qp->log(LOGDEBUG, @_) },
					errorlogger => sub { $qp->log(LOGINFO, @_) },
				);
			}
		}

		return 1;
	}) or return DECLINED;
	$qp->log(LOGDEBUG, "quarantine returning: @retcode");
	return @retcode;
}

sub initialize
{
	my ($qp, $oops, $transaction) = @_;
	require Data::Dumper;
#	my $qa = $qp->{_quarantine};
	die unless $qa->{our_networks};
	my $qd = $oops->{quarantine} = bless {
		senders		=> (bless {}, 'Quarantine::Senders'),
		headers		=> (bless {}, 'Quarantine::Headers'),
		bodies		=> (bless {}, 'Quarantine::Bodies'), 
		buckets3	=> (bless {}, 'Quarantine::Buckets'),
		recipients	=> (bless {}, 'Quarantine::Recipients'),
		mqueue		=> (bless {}, 'Quarantine::MailQueue'),
		diskused	=> (bless {}, 'Quarantine::DiskUsage'),
		version		=> $VERSION,
	}, 'Quarantine::Top';
	$oops->virtual_object($qd->{headers}, 1);
	$oops->virtual_object($qd->{bodies}, 1);
	$oops->virtual_object($qd->{senders}, 1);
	$oops->virtual_object($qd->{recipients}, 1);
	$oops->virtual_object($qd->{mqueue}, 1);
	$oops->virtual_object($qd->{diskused}, 1);

	# make a pseudo-random token
	my $header_checksum = md5_hex($transaction->header()->as_string());
	my $time = Time::HiRes::time();
	my $stuff1 = "$$.$header_checksum.$time.";
	my $stuff2 = join('?',values(%$qa));


	my $stuff3;
	open(RANDOM, "/dev/random") || next;
	read(RANDOM, $stuff3, 32, 0);
	close(RANDOM);

	$qd->{random_token} = md5_hex($stuff1).md5_hex($stuff2).md5_hex($stuff3);

	$qp->log(LOGWARN, "Quarantine data structures initialized");

	return $qd;
}

sub send_recipient_notification
{
	my ($qp, $transaction, $r, $rd, $qd) = @_;
	my $headers = $transaction->header();
	my $buf;
	my (undef, $domain) = split('@', $r);
	$qa->{template}->process('recipient-notification.mail', {
		config		=> \%defaults,
		recipient	=> $r,
		mcount		=> $rd->{mcount},
		domain		=> $domain,
		headers		=> $headers,
		sender		=> $transaction->sender(),
		recipient_url	=> $rd->url($qd),
		now		=> scalar(localtime(time)),
	}, \$buf);
	$buf =~ s/\A\s*//s;
	return {
		recipient	=> $r,
		message		=> $buf,
	};
}

sub get_message_info
{
	my ($qp, $transaction) = @_;

#	my $qa = $qp->{_quarantine} = {};
	die unless $qa->{our_networks};
	my $headers = $transaction->header();

	if (0 && $debug) {
		$qp->log(LOGDEBUG, "Our stuff...");
		for my $i (sort keys %{$qa->{our_domains}}) {
			$qp->log(LOGDEBUG, "Our domain: $i");
		}
		for my $i (sort keys %{$qa->{filter_domains}}) {
			$qp->log(LOGDEBUG, "Filter domain: $i");
		}
		for my $i (dumpNetworkTable($qa->{our_networks})) {
			$qp->log(LOGDEBUG, "Our netblock: $i");
		}
		for my $i (dumpNetworkTable($qa->{ignore_networks})) {
			$qp->log(LOGDEBUG, "Ignore netblock: $i");
		}
	}

	unless ($transaction->notes('origin_type')) {
		my $external_ip;
		my $internal_ip;
		for my $received_line ($headers->get('Received')) {
			# $qp->log(LOGDEBUG, "Processing Received line: $received_line");
			my $received = Mail::Field->new('Received', $received_line);
			if ($received->parsed_ok()) {
				my $pt = $received->parse_tree();
				my $ip = $pt->{from}{address};
				my $our_block = findNetblock($ip, $qa->{our_networks});
				if ($our_block) {
					$internal_ip = $ip;
					$qp->log(LOGDEBUG, "Found an internal address: $ip, will see if there's more...");
					next;
				} 
				my $ignore_block = findNetblock($ip, $qa->{ignore_networks});
				if ($ignore_block) {
					$qp->log(LOGDEBUG, "IP address should be ignored ($ip)");
					next;
				}
				unless ($ip) {
					$qp->log(LOGDEBUG, "No IP address found in: $received_line");
					next;
				}
				$qp->log(LOGDEBUG, "Looked for $ip, but isn't one of ours");
				$external_ip = $ip;
				# $qp->log(LOGDEBUG, "sender host:", $transaction->sender->host());
				# $qp->log(LOGDEBUG, "sender user:", $transaction->sender->user());
				$qp->log(LOGDEBUG, "sender address:", $transaction->sender->address());

				$transaction->notes(
					entry_ip	=> $ip,
					entry_helo	=> $pt->{from}{HELO},
					entry_domain	=> $pt->{by}{domain},
				);
					
				last;
			} else {
				$qp->log(LOGWARN, "Mail::Field::Received failed: ", $received->diagnostics());
				last;
			}
		}

		if ($external_ip) {
			$transaction->notes(external_ip => $external_ip);
			$transaction->notes(origin_type => 'external');
			$qp->log(LOGDEBUG, "External IP origin: $external_ip");
		} else {
			$transaction->notes(origin_type => 'internal');
			$qp->log(LOGDEBUG, "Internal IP origin: $internal_ip");
		}
	}

	unless (defined $transaction->notes('from_our_domain')) {
		my $sdomain = $transaction->sender->host();
		my $from_our_domain = match_domain($qp, $sdomain, $qa->{our_domains}, 'our_domains');
		$transaction->notes(from_our_domain => $from_our_domain);
		$qp->log(LOGDEBUG, "From our domain: $from_our_domain ($sdomain)");
	}

	unless (defined $transaction->notes('filtered_recipient_count')) {
		my @rdomains =  map { $_->host() } $transaction->recipients();
		my $filter_count = 0;
		for my $rd (@rdomains) {
			$filter_count++ if match_domain($qp, $rd, $qa->{filter_domains}, 'filter_domains');
		}
		$transaction->notes(filtered_recipient_count => $filter_count);
		$qp->log(LOGDEBUG, "Filtered Recipient Count: $filter_count");
	}
}


sub spf
{
	my ($qp, $transaction) = @_;

	my $done = $transaction->notes('spf_result');
	return $done if $done;

	get_message_info($qp, $transaction)
		unless $transaction->notes('origin_type');

	return '' 
		unless $transaction->notes('origin_type') eq 'external';

	my $ip = $transaction->notes('entry_ip');
	my $sender = $transaction->sender->address();
	my $entry_helo = $transaction->notes('entry_helo');
	$qp->log(LOGDEBUG, "SPF Query with ip=$ip, sender=$sender, helo='$entry_helo'");
	my $spf = new Mail::SPF::Query (
		ip		=> $ip,
		sender		=> $sender,
		helo		=> $entry_helo,
		myhostname	=> ($transaction->notes('entry_domain') || $myhostname),
		debug		=> 0,
		debuglog	=> sub { $qp->log(LOGDEBUG, @_) },
		trusted		=> 1,
		guess		=> 1,
		sanitize	=> 0,
	);
	my $result = ($spf->result())[0];
	$qp->log(LOGDEBUG, "SPF results: $result");
	$transaction->notes(spf_result => $result);
	return $result;
}

sub match_domain
{
	my ($qp, $domain, $hashref, $what) = @_;
	while ($domain) {
		$qp->log(LOGDEBUG, "Trying to match $domain for $what");
		if ($hashref->{$domain}) {
			return 1;
		} 
		$domain =~ s/^[^\.]+// or last;
		$domain =~ s/^\.//;
	}
	return 0;
}

