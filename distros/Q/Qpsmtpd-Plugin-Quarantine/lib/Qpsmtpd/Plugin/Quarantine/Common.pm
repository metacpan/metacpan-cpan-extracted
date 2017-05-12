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


package Qpsmtpd::Plugin::Quarantine::Common;

use Time::HiRes;
use OOPS;
use Digest::MD5 qw(md5_hex);
use File::Slurp;
use CGI qw();
require Exporter;
use Sys::Hostname;
use strict;

our @ISA = qw(Exporter);
our @EXPORT = qw(new_sender new_recipient get_oops oops_args %defaults %escape recompute_defaults);
our @EXPORT_OK = qw(%base_defaults);

our $myhostname = hostname();

# ------------------------------- begin defaults section ------------------------------------------------

#
# These defaults can be overridden in the defaults_file (see below) or
# in the Qpsmtpd plugins configuration file.  The location of the defaults
# file can't be overridden.  The location of the Qpsmtpd configuration
# directory can only be overridden by the defaults_file.
#
our %base_defaults = (
	#
	# Configuration files
	#
	defaults_file		=> '/etc/default/qpsmtpd-quarantine.pl',
	templates		=> "/etc/qpsmtpd/quarantine-templates",
	qpsmtpd_dir		=> '/etc/qpsmtpd',
	admin_passwd_file	=> "/etc/qpsmtpd/quarantine.access",		# htpasswd style user file
	notify_recipient_only	=> "/etc/qpsmtpd/recipient.special.db",		# notify these recipients instead of senders
	special_sender_db	=> "/etc/qpsmtpd/sender.special.db",		# always check mail from these senders
	# $qpsmtpd_dir/filter_domains		- list of domain names that might blacklist us
	# $qpsmtpd_dir/our_domains		- list of domain names that are us
	# $qpsmtpd_dir/our_networks		- list of IP addresses a.b.c.d/size that are us
	# $qpsmtpd_dir/ignore_networks		- list of IP addresses a.b.c.d/size that don't count

	#
	# Data Store
	#
	dbi_dsn			=> $ENV{OOPS_DSN} || 'DBI::SQLite:dbname=/var/spool/qpsmtpd-quarantine.db',
	username		=> "biteme",	# database user
	password		=> "harder",	# database password
	table_prefix		=> 'q',		# see OOPS documentation

	#
	# Identity
	#
	send_from		=> "root\@$myhostname",
#	baseurl			=> "http://$myhostname/perl/quarantine.pl",    # mod_perl with Apache::Registry
	baseurl			=> "http://$myhostname/quarantine.cgi",
	bounce_from		=> "MAILER-DAEMON\@$myhostname",

	#
	# Spam filtering
	#
	spamd3			=> {
		'spamc -R -d 127.0.0.1 <'	=>  100,	# can use a farm of servers, value is load share weighting
	},
	accessio		=> '', # see http://www.miavia.com
	clamd			=> '/usr/bin/clamdscan --stdout - <',
	clamav			=> '/usr/local/bin/clamscan --stdout',
	virus_content 		=> qr/(?:application|name=.*\.(?:asd|bat|chm|cmd|com|cpl|dll|exe|hlp|hta|js|jse|lnk|ocx|pif|rar|scr|shb|shm|shs|vb|vbe|vbs|vbx|vxd|wsf|wsh|zip))/i,
	subcommand_timeout	=> 150,

	#
	# Bounce message
	#
	senderbounce1		=> 'Your message is quarantined because we think it is probably spam, if it is not spam, click',
	senderbounce2		=> 'to release your message from quarantine or to choose to have the spam you send silently deleted instead of bounced',
	senderbounce3		=> 'None of the recipients of your email wish to receive mail that is likely to be spam',

	#
	# Networks
	#
	ignore_networks		=> [ qw(127.0.0.0/8 10.0.0.0/8 172.16/12 192.168/16) ],

	#
	# Mail configuration
	#
	bypass_mailhosts	=> [qw(127.0.0.1)],			# Where to SMTP-inject messages (post-filter)
	bypass_mailcmd		=> [qw(/usr/sbin/sendmail -oeml -i)],	# ... if that didn't work
	nobody_address		=> "nobody\@$myhostname",		# this user should silently discard


	#
	# Quarantine behavior
	#
	check_all_recipients	=> 0,		# Check mail to non-filtered domains for spam too
	randomly_check_messages	=> 1,		# check N % of messages regardless
	check_from_our_domain	=> 0,		# Force a check of mail from our domains even if not to a filtered destination
	check_not_our_domain	=> 0,		# Force a check of mail not from our domains even if not to a filtered destination
	check_from_our_ip	=> 0,		# Force a check of mail from our netblock even if not to a filtered destination
	check_not_from_our_ip	=> 0,		# Force a check of mail not from our netblock even if not to a filtered destination
	renotify_sender_ip	=> 10,		# Send a bounce every N days (per IP, per sender)
	notify_recipients	=> 75,		# After N messages, notify the recipient instead (0 = disable)
	renotify_recipient_days	=> 10,		# Notify recipients every N days (when there is a new message)
	max_bounces_per_header	=> 3,		# allow N bounes with our URL to bypass the filter (per message URL)
	notify_other_senders	=> 0,		# send bounces to external senders?

	#
	# Cron job config
	#
	sender_stride_length	=> 40,		# when cleaning, process N senders per transaction
	recipient_stride_length	=> 40,		# when cleaning, process N recipients per transaction
	sender_history_to_keep	=> 20,		# how many days spamming history to keep per sender
	keep_every_nth_message	=> 200,		# quarantine every Nth spam per sender (regardless of sender settings)
	report_senders_after	=> 100,		# minimum number of spams required to make a report on a sender
	message_longevity	=> 30,		# how long to keep messages in quarantine (days)
	delete_batchsize	=> 50,		# how many messages to delete per transaction
	keep_idle_recipients	=> 720,		# how long to keep idle recipients that have settings (days)
	message_store_size	=> 1500,	# Megabytes

	#
	# Internal data structures
	#
	size_storage_array_size	=> 256,		# transaction parallism
	message_size_overhead	=> 500,		# header, etc

	#
	# Internal Mail Queue
	#
	mqueue_stride_length	=> 50,		# when sending mail, process N recipients per transaction
	mqueue_minimum_attempts	=> 100,		# how many times to try sending something
	mqueue_minimum_gap	=> 900,		# minimum time between attempts (seconds)
	mqueue_maximum_keep	=> 3,		# days to keep trying

	#
	# Form buttons.  All values must be distinct.
	#
	button_login			=> 'Login',
	button_logout			=> 'Log Out',
	button_lookup_email		=> 'Lookup Email Address',
	button_sender_update		=> 'Update Sender Settings',
	button_sender_delete		=> 'Delete',
	button_sender_send		=> 'Send To Recipient',
	button_sender_url		=> 'Send Me An Settings Access URL',
	button_sender_send_checked	=> 'Send Checked Messages To Recipients',
	button_sender_delete_all	=> 'Delete All Messages',
	button_sender_delete_checked	=> 'Delete Checked Messages',
	button_sender_replace_token	=> 'ReplaceSenderToken',
	button_sender_reset_timer	=> 'Reset Bounce Notification Timer',
	button_recipient_update		=> 'Update My Settings',
	button_recipient_url		=> 'Send Me An Access URL',
	button_recipient_replace_token	=> 'ReplaceToken',
#	button_recipient_reset_timer	=> 'Reset Notification Timer',

);

# ------------------------------- end defaults section --------------------------------------------------

sub FuncT::TIEHASH { my $p = shift; return bless shift, $p } 
sub FuncT::FETCH { my $f = shift; return &$f(shift) } 

tie our %escape, 'FuncT', \&CGI::escape;

do $base_defaults{defaults_file} if -e $base_defaults{defaults_file};

our %defaults;

recompute_defaults();

sub recompute_defaults
{
	%defaults = %base_defaults;

	my $qpsmtpd_plugins = "$base_defaults{qpsmtpd_dir}/plugins";

	my ($cl) = grep(s/^quarantine\s+//, read_file($qpsmtpd_plugins));
	my (%config) = split(' ', $cl);

	@defaults{keys %config} = values %config;

	@Mail::SendVarious::mail_command = @{$defaults{bypass_mailcmd}};
	@Mail::SendVarious::mail_hostlist = @{$defaults{bypass_mailhosts}};
}

sub new_sender
{
	my ($oops, $hostdomain, $address, $sender_token) = @_;

	$sender_token = md5_hex($$ . Time::HiRes::time() . $hostdomain)
		unless $sender_token;

	my $psender = $oops->{quarantine}{senders}{$hostdomain} = bless {
		canonical	=> $hostdomain,
		address		=> $address,
		token		=> $sender_token,
		headers		=> {},
		send_ip_used	=> {},
	}, 'Quarantine::Sender';
	$oops->virtual_object($psender->{headers});
	$oops->virtual_object($psender->{send_ip_used});
	return $psender;
}

sub new_recipient
{
	my ($oops, $address) = @_;
	my $qd = $oops->{quarantine} || die;
	my $rd = $qd->{recipients}{$address} = bless {
		address		=> $address,
		mcount		=> 0,
		headers		=> {},
	}, 'Quarantine::Recipient';
	$oops->virtual_object($rd->{headers}, 1);
	return $rd;
}

sub get_oops
{
	my ($config, %extra) = @_;
	my $oops = new OOPS 
		oops_args($config), 
		%extra;
	return $oops;
}

sub oops_args
{
	return (
		dbi_dsn		=> $defaults{dbi_dsn},
		user		=> $defaults{username},
		password	=> $defaults{password},
		table_prefix	=> $defaults{table_prefix},
		auto_initialize	=> 1,
		auto_upgrade	=> 1,
	);
}

my $config_pointer;

#sub get_config
#{
#	return $config_pointer if $config_pointer;
#
#	my $qpsmtpd_plugins = "$base_defaults{qpsmtpd_dir}/plugins";
#
#	my ($cl) = grep(s/^quarantine\s+//, read_file($qpsmtpd_plugins));
#	my (%config) = split(' ', $cl);
#
#	$config_pointer = \%config;
#	return \%config;
#}

#sub config_item 
#{
#	my ($item, $config) = @_;
#	$config = get_config()
#		unless $config;
#	return $config->{$item}
#		if exists $config->{$item};
#	return $defaults{$item}
#		if exists $defaults{$item};
#	die "No config or default for '$item'";
#}

package Quarantine::Sender;

use strict;
use Qpsmtpd::Plugin::Quarantine::Common;

sub url
{
	my ($psender) = @_;

	die unless ref($psender);
	return "$defaults{baseurl}/sender/$psender->{token}/$escape{$psender->{canonical}}";
}

sub has_settings
{
	my ($psender) = @_;
	return 1 if $psender->{action};
	return 1 if $psender->{renotify_days};
	return 0;
}

package Quarantine::Recipient;

use strict;
use Digest::MD5 qw(md5_hex);
use Qpsmtpd::Plugin::Quarantine::Common;
use Carp;

sub url
{
	my ($rd, $qd) = @_;

	croak unless ref($rd);
	croak unless ref($qd);
	croak unless $rd->{address};
	my $token = $rd->{token} || md5_hex($qd->{random_token} . $rd->{address});

	return "$defaults{baseurl}/recipient/$token/$escape{$rd->{address}}";
}

sub has_settings
{
	my ($psender) = @_;
	return 1 if $psender->{action};
	return 1 if $psender->{token};
	return 1 if $psender->{new_address};
	return 0;
}

1;
