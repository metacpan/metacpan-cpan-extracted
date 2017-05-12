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

package Qpsmtpd::Plugin::Quarantine::CGI;

use CGI qw();
use CGI::Cookie;
use Carp qw(longmess);
use OOPS;
use File::Slurp;
use Data::Dumper;
use strict;
use Template;
use Net::SMTP;
use Scalar::Util qw(refaddr);
use Digest::MD5 qw(md5_hex);
use Time::CTime;
use Time::ParseDate;
use Qpsmtpd::Plugin::Quarantine::Common;
use Qpsmtpd::Plugin::Quarantine::Sendmail;
use Mail::SendVarious;

our @ISA = qw(Exporter);
our @EXPORT = qw(main);

require Exporter;

use strict;

my $template;

my $random_token;

my $cgi = new CGI;
my $md5rx = qr/[a-f0-9]{32}/;
my $pi;
my $debug = 1;

my $filtered_domains;

my $cookie_time_fmt = "%A, %d-%b-%Y %X GMT";

sub error {
	local($Carp::CarpLevel) = 1;
	print STDERR longmess(@_);
	die "\n";
}

sub main
{
	$filtered_domains = "$defaults{qpsmtpd_dir}/filter_domains";

	$cgi = new CGI;

	$template = Template->new({
		INCLUDE_PATH	=> $defaults{templates},
		INTERPOLATE	=> 1,
		POST_CHOMP	=> 0,
		EVAL_PERL	=> 1,
		RECURSION	=> 1,
	}) || error Template->error();

	$pi = $cgi->path_info();

	transaction(sub {
		my $oops = get_oops();
		$random_token = $oops->{quarantine}{random_token};
		if ($pi =~ m{^/message/($md5rx)$}) {
			handle_message($oops,$1);
		} elsif ($pi =~ m{^/sender/($md5rx)/(.*)$}i) {
			handle_sender($oops, $2, $1);
		} elsif ($pi =~ m{^/recipient/($md5rx)/(.+)$}i) {
			handle_recipient($oops, $2, $1);
		} elsif ($pi =~ m{^/recipient/(.*)$}i) {
			handle_unauthorized_recipient($oops, $1);
		} elsif ($pi =~ m{^/admin}) {
			handle_admin($oops);
		} else {
			print $cgi->header();
			$template->process('main-menu.tt2', { cgi => $cgi, config => \%defaults}) || error $Template::ERROR;
		}
	});
	print STDERR "E=$@\n" if $@;
	error $@ if $@;

	send_postponed();
	print STDERR "Done\n";
}

sub handle_unauthorized_sender
{
	my ($oops, $sender_encoded) = @_;

	print $cgi->header();

	my $qd = $oops->{quarantine} || error;

	my $sender = CGI::unescape($sender_encoded) || $cgi->param('sender');

	my $action = $cgi->param('action') || '';

	my $psender = $qd->{senders}{$sender};
	my $token = $psender && $psender->{token};

	if ($action eq $defaults{button_sender_url} && $sender =~ /^([^\@]+)\@([^\@]+)$/) {
		my $buf;
		# sender may not exist yet
		if ($psender) {
			$token = md5_hex($$ . Time::HiRes::time() . $qd->{random_token} . $sender);
			$psender->{token} = $token;
			print STDERR "New token for $sender: $token\n";
		} else {
			$psender = new_sender($oops, $1, $sender);
			$token = $psender->{token};
			print STDERR "First token for $sender: $token\n";
		} 
		$oops->commit();
		$template->process('sender-notification.mail', {
			config		=> \%defaults,
			sender		=> $sender,
			request_ip	=> $ENV{REMOTE_ADDR} || $ENV{REMOTE_HOST},
			sender_url	=> $psender->url(),
			now		=> scalar(localtime(time)),
		}, \$buf) || error $Template::ERROR;
		print STDERR "Message to send to $sender:\n$buf" if $debug;
		sendmail_or_postpone(from => $defaults{send_from}, to => $sender, message => $buf);
		$template->process('sender-access-url-sent.tt2', {
			config	=> \%defaults,
			sender	=> $sender,
		}) || error $Template::ERROR;
	} else {
		$template->process('unauthorized-sender.tt2', {
			config	=> \%defaults,
			sender	=> $sender
		}) || error $Template::ERROR;
	}
}

sub handle_sender
{
	my ($oops, $sender_encoded, $sender_checksum) = @_;

	print $cgi->header();

	my $qd 		= $oops->{quarantine} || error;
	my $sender	= CGI::unescape($sender_encoded);
	my $action	= $cgi->param('action') || '';
	my $psender	= $qd->{senders}{$sender};
	my $docommit	= 0;

	unless ($psender) {
		$psender = new_sender($oops, $sender, $sender);
		$docommit = 1;
	}

	my $correct_checksum = $psender->{token};
	
	if ($action eq $defaults{button_sender_url}) {
		return handle_unauthorized_sender($oops, $sender_encoded);
	}

	if ($sender_checksum ne $correct_checksum) {
		my %error = ();
		%error = (
			error		=> 'Your URL is invalid',
			error_detail	=> 'The URL you used does not contain the correct authentication tokens for your email address.  Please ask for a new authentication URL.',
			
		) if $sender;
		$template->process('unauthorized-sender.tt2', {
			config		=> \%defaults,
			sender		=> $sender,
			%error,
		}) || error $Template::ERROR;
		print STDERR "CHECKSUM MISMATCH $sender_checksum vs $correct_checksum\n";
		return;
	}

	my %extra;
	my %args = (
		sender		=> $sender,
		psender		=> $psender,
		sender_url	=> $psender->url(),
		config		=> \%defaults,
		otherheaders	=> [ grep(! $_->{done}, values %{$psender->{headers}}) ],
	);

	my ($acommit, $doform, @message) = sender_action($oops, $sender, $psender, $action, \%args, 1);
	$docommit ||= $acommit;

	$oops->commit() if $docommit;

	$extra{message} = message('Sender', @message);

	if ($doform) {
		$template->process('sender-menu.tt2', {
			%extra, 
			%args,
		}) || error $Template::ERROR;
	}
}

sub sender_action
{
	my ($oops, $sender, $psender, $action, $args, $canshow) = @_;


	my $qd = $oops->{quarantine} || error;
	my $docommit = 0;
	my $doform = 1;
	my @message;
	if ($action eq $defaults{button_sender_update}) {
		my $na = $cgi->param('new_action');
		my $bf = $cgi->param('renotify_days');
		if ($na ne ($psender->{action} || 'quarantine')) {
			$psender->{action} = $na;
			if ($na eq 'discard') {
				push(@message, "When we think a message from you might be SPAM, we'll just drop it.");
			} elsif ($na eq 'quarantine') {
				push(@message, "When we think a message from you might be SPAM, we'll quarantine so that you can verify that it isn't spam.");
			} elsif ($na eq 'bounce') {
				push(@message, "When we think a message from you might be SPAM, we'll bounce it.");
			} else {
				error;
			}
		}
		if ($bf != ($psender->{renotify_days} || $defaults{renotify_sender_ip})) {
			$psender->{renotify_days} = $bf;
			push(@message, "You will only be notified every $bf days (per IP address) if we think a message might be spam");
		}
		$docommit = 1;
	} elsif ($action eq $defaults{button_sender_reset_timer}) {
		if (%{$psender->{send_ip_used}}) {
			$psender->{sender}{send_ip_used} = {};
			$docommit = 1;
			push(@message, "Notification timers reset");
		}
	} elsif ($action eq $defaults{button_sender_replace_token}) {
		require Time::HiRes;
		$psender->{token} = md5_hex($qd->{random_token} . $sender . Time::HiRes::time() . $$ . $ENV{REMOTE_HOST} . $ENV{REMOTE_ADDR});
		$oops->commit;
		$docommit = 0;

		my $buf;
		$template->process('sender-notification.mail', {
			%$args,
			sender_url	=> $psender->url(),
			request_ip	=> $ENV{REMOTE_ADDR} || $ENV{REMOTE_HOST},
			now		=> scalar(localtime(time)),
		}, \$buf) || error $Template::ERROR;

		sendmail_or_postpone(from => $defaults{send_from}, to => $sender, message => $buf);

		if ($canshow) {
			$template->process('access-url-sent.tt2', {
				config		=> \%defaults,
				recipient	=> $sender,
			}) || error $Template::ERROR;
			print STDERR "## New sender token sent to $sender\n";
			$doform = 0;
		} else {
			push(@message, "New sender token sent to $sender");
		}
	} elsif ((undef, $docommit, @message) = handle_other_messages($oops, $psender, $action, $args, undef)) {
		# nada
	} elsif (! $action) {
		# nada
	} else {
		error "action=$action";
	}
	return ($docommit, $doform, @message);
}


sub handle_other_messages
{
	my ($oops, $psender, $action, $templateargs, $tt2) = @_;

	my $do;
	my $set;
	if ($action eq $defaults{button_sender_delete_checked}) {
		$do = 'delete';
		$set = 'checked';
	} elsif ($action eq $defaults{button_sender_delete_all}) {
		$do = 'delete';
		$set = 'all';
	} elsif ($action eq $defaults{button_sender_send_checked}) {
		$do = 'send';
		$set = 'checked';
	} else {
		return 0;
	}

	my @set;
	for my $hsum (keys %{$psender->{headers}}) {
		next if $psender->{headers}{$hsum}{done};
		push(@set, $psender->{headers}{$hsum}) if $set eq 'all' || $cgi->param("cb-".$hsum);
	}
	my @message;
	if ($do eq 'delete') {
		for my $h (@set) {
			message_handled($oops, $h, 'deleted');
			push(@message, "Deleted message w/Subject $h->{subject}");
		}
	} else {
		for my $h (@set) {
			message_handled($oops, $h, 'sent');
			sendmail_or_postpone(from => ($h->{sender}{address} || '<>'), to => $h->{recipients}, header => $h->{header}, body => $h->{body}{body});
			push(@message, "Sent message w/Subject $h->{subject}");
		}
	}
	return (1, 1, @message) unless $tt2;
	$oops->commit();
	my $message = message('Sender', @message);
	$template->process($tt2, {
		%$templateargs,
		message => $message,
	}) || error $Template::ERROR;
	return 1;
}

sub message_handled
{
	my ($oops, $h, $how) = @_;
	error if $h->{done};
	$h->{done} = $how;
	my $qd = $oops->{quarantine} || error;
	for my $r (@{$h->{recipients}}) {
		my $rd = $qd->{recipients}{$r};
		if ($rd->{headers}{$h->{cksum}}) {
			$rd->{mcount}--;
		}
	}
}

sub handle_recipient
{
	my ($oops, $recipient_encoded, $recipient_checksum) = @_;

	print $cgi->header();

	my $qd 		= $oops->{quarantine} || error;
	my $recipient	= CGI::unescape($recipient_encoded);
	my $action	= $cgi->param('action') || '';
	my $rd		= $qd->{recipients}{$recipient};

	$rd = new_recipient($oops, $recipient)
		unless $rd;

	my $correct_checksum = $rd->{token} || md5_hex($qd->{random_token} . $recipient);

	if ($action eq $defaults{button_recipient_url}) {
		return handle_unauthorized_recipient($oops, $recipient_encoded);
	}

	if ($recipient_checksum ne $correct_checksum) {
		$template->process('unauthorized-recipient.tt2', {
			config		=> \%defaults,
			recipient	=> $recipient,
			error		=> 'Your URL is invalid',
			error_detail	=> 'The URL you used does not contain the correct authentication tokens for your email address.  Please ask for a new authentication URL.',
		}) || error $Template::ERROR;
		print STDERR "CHECKSUM MISMATCH $recipient_checksum vs $correct_checksum\n";
		return;
	}

	my %args = (
		config		=> \%defaults,
		recipient	=> $recipient,
		rd		=> $rd,
	);

	(my $showform, my @message) = recipient_action($oops, $recipient, $rd, \%args, 1, $action);

	my $message = message('Sender', @message);

	if ($showform) {
		$template->process('recipient-menu.tt2', {
			message => $message,
			%args,
		}) || error $Template::ERROR;
	}
}

sub recipient_action
{
	my ($oops, $recipient, $rd, $args, $canshow, $action) = @_;
	my $qd = $oops->{quarantine} || error;
	my @message;
	my $docommit;
	my $showform = 1;
	if ($action eq $defaults{button_recipient_update}) {
		my $na = $cgi->param('new_action');
		if ($na eq 'drop') {
			$rd->{action} = 'drop';
			$oops->commit();
			print STDERR "We will now drop messages for $recipient\n";
			push(@message, 'Settings changed: spammy messages for you will now be dropped');
		} elsif ($na eq 'quarantine') {
			delete $rd->{action};
			$oops->commit();
			print STDERR "We will now quarantine messages for $recipient\n";
			push(@message, 'Settings changed: spammy messages for you will now be quarantined');
		} elsif ($na eq 'forward') {
			require Mail::Address;
			my ($new, @junk) = Mail::Address->parse($cgi->param('new_address'));
			if (! $new or @junk or ! $new->host) {
				push(@message, 'Please enter a simple address (user@host) for forwarding');
			} else {
				if (domain_is_filtered($new->host)) {
					push(@message, 'You cannot forward to @'.$new->host.' addresses because they suffer from the same problem that your current address has');
				} else {
					my @tosend;
					for my $hsum (keys %{$rd->{headers}}) {
						my $h = $rd->{headers}{$hsum};
						next if $h->{done};
						delete $rd->{headers}{$hsum};
						push(@tosend, {
							to	=> $recipient,
							sender	=> $h->{sender}{address},
							header	=> $h->{header},
							body	=> $h->{body},
						});
						my @newrlist = grep( $_ ne $recipient, @{$h->{recipients}});
						message_handled($oops, $h, 'done') unless @newrlist;
						$h->{recipients} = bless [ @newrlist ], 'Quarantine::RecipientList';
					}
					send_queued($new->format, @tosend);
					$rd->{action} = 'forward';
					$rd->{new_address} = $new->format;
					$oops->commit();
					push(@message, sprintf("Settings changed: spammy messages for you will now be forwarded.  Quarantined messages released: %d", scalar(@tosend)));

					my $buf;
					$template->process('recipient-forwarding.mail', {
						%$args,
						new_address	=> $new->format,
						request_ip	=> $ENV{REMOTE_ADDR} || $ENV{REMOTE_HOST},
						recipient_url	=> $rd->url($qd),
						now		=> scalar(localtime(time)),
					}, \$buf) || error $Template::ERROR;

					print STDERR "Message to send to $recipient:\n$buf" if $debug;

					sendmail_or_postpone(from => $defaults{send_from}, to => $new->address, message => $buf);

				}
			}
		} else {
			error;
		}
	} elsif ($action eq $defaults{button_recipient_replace_token}) {
		require Time::HiRes;
		$rd->{token} = md5_hex($qd->{random_token} . $recipient . $rd->{new_address} . Time::HiRes::time() . $$ . $ENV{REMOTE_HOST} . $ENV{REMOTE_ADDR});
		$oops->commit;

		my $buf;
		$template->process('recipient-notification.mail', {
			%$args,
			request_ip	=> $ENV{REMOTE_ADDR} || $ENV{REMOTE_HOST},
			recipient_url	=> $rd->url($qd),
			now		=> scalar(localtime(time)),
		}, \$buf) || error $Template::ERROR;

		print STDERR "Message to send to $recipient:\n$buf" if $debug;

		sendmail_or_postpone(from => $defaults{send_from}, to => $recipient, message => $buf);

		if ($rd->{action} eq 'forward') {
			print STDERR "ALSO Message to send to $rd->{new_address}\n" if $debug;
			sendmail_or_postpone(from => $defaults{send_from}, to => $rd->{new_address}, message => $buf);
		}

		if ($canshow) {
			$template->process('access-url-sent.tt2', {
				%$args,
			}) || error $Template::ERROR;
			$showform = 0;
		} else {
			push(@message, "Recipient access URL sent");
		}
	}
	return($showform, @message);
}

sub handle_unauthorized_recipient
{
	my ($oops, $recipient_encoded) = @_;

	print $cgi->header();

	my $qd = $oops->{quarantine} || error;

	my $recipient = CGI::unescape($recipient_encoded) || $cgi->param('recipient');

	my $action = $cgi->param('action') || '';

	my $rd = $qd->{recipients}{$recipient};
	my $token = ($rd && $rd->{token}) || md5_hex($qd->{random_token} . $recipient);

	if ($action eq $defaults{button_recipient_url} && $recipient =~ /^[^\@]+\@([^\@]+)$/) {
		my $buf;
		# recipient may not exist yet
		$template->process('recipient-notification.mail', {
			config		=> \%defaults,
			recipient	=> $recipient,
			request_ip	=> $ENV{REMOTE_ADDR} || $ENV{REMOTE_HOST},
			recipient_url	=> "$defaults{baseurl}/recipient/$token/$escape{$recipient}",
			now		=> scalar(localtime(time)),
		}, \$buf) || error $Template::ERROR;
		print STDERR "Message to send to $recipient:\n$buf" if $debug;
		sendmail_or_postpone(from => $defaults{send_from}, to => $recipient, message => $buf);
		if ($rd && ($rd->{action} eq 'forward')) {
			print STDERR "ALSO Message to send to $rd->{new_address}\n" if $debug;
			sendmail_or_postpone(from => $defaults{send_from}, to => $rd->{new_address}, message => $buf);
		}
		$template->process('access-url-sent.tt2', {
			config		=> \%defaults,
			recipient	=> $recipient,
		}) || error $Template::ERROR;
	} else {
		$template->process('unauthorized-recipient.tt2', {
			config		=> \%defaults,
			recipient	=> $recipient
		}) || error $Template::ERROR;
	}
}


sub handle_message
{
	my ($oops,$hdr_sum) = @_;

	print $cgi->header();

	my $qd = $oops->{quarantine} || error;

	my $h = $qd->{headers}{$hdr_sum};

	unless ($h) {
		$template->process('error.tt2', {
			config	=> \%defaults,
			error	=> "Message not found",
			verbose	=> "Your message was not found in our database.   We expire messages fairly quickly so it may be that you waited too long.  Please re-send your original message to start the process over again."
		}) || error $Template::ERROR;
		return;
	};

	my $otherheaders	= [ grep(refaddr($_) != refaddr($h) && ! $_->{done}, values %{$h->{sender}{headers}}) ];
	my $repeat		= ($cgi->referer() =~ /\Q$defaults{baseurl}\E/);
	my (%args) = (
		header		=> $h,
		sender		=> $h->{sender}{canonical},
		psender		=> $h->{sender},
		recipients	=> join(', ', @{$h->{recipients}}),
		otherheaders	=> $otherheaders,
		repeat		=> $repeat,
		config		=> \%defaults,
		baseurl		=> $defaults{baseurl},
		sender_url	=> $h->{sender}->url(),
	);

	my $action = $cgi->param('action') || '';
	print STDERR "Action = '$action'\n" if $debug;
	if ($action eq $defaults{button_sender_delete}) {
		message_handled($oops, $h, 'deleted');
		$oops->commit();
		$template->process('sender-action-taken.tt2', {
			%args,
			code	=> 'DELETE',
			message	=> "Your message was deleted.  Thank you.",
		}) || error $Template::ERROR;
	} elsif ($action eq $defaults{button_sender_send}) {
		sendmail_or_postpone(from => $h->{sender}{address}, to => $h->{recipients}, header => $h->{header}, body => $h->{body}{body});
		message_handled($oops, $h, 'sent');
		$oops->commit();
		$template->process('sender-action-taken.tt2', {
			%args,
			code	=> 'SENT',
			message	=> 'Your message was released from quarantine and is now on its way to its destination',
		}) || error $Template::ERROR;
	} elsif ($action eq 'Discard My Mail') {
		$h->{sender}{silentely_discard} = {
			host	=> $cgi->remote_host(),
			agent	=> $cgi->user_agent(),
			date	=> time,
		};
		$oops->commit();
		$template->process('sender-action-taken.tt2', {
			%args,
			code	=> 'DISCARD_ALL',
			message	=> 'Mail from you that we think is spam will be silently discarded.  This is not reversable.  Do not ask.',
		}) || error $Template::ERROR;
	} elsif ($action eq '') {
		if ($h->{sender}{send_ip_used}) {
			$h->{sender}{send_ip_used} = {};
			$oops->commit();
		}
		my $x;
		$template->process('message-menu.tt2', \%args, \$x) or error $Template::ERROR;
#		print STDERR "X=$x\n";
		print $x;
	} elsif (handle_other_messages($oops, $h->{sender}, $action, \%args, 'message-menu.tt2')) {
		# nada
	} else {
		error "action=$action";
	}
}

sub handle_admin
{
	my ($oops) = @_;

	my $qd = $oops->{quarantine} || error;

	my (%cookies) = CGI::Cookie->fetch();

	my %args = ( config => \%defaults );
	my $authorized = 0;
	my $action = $cgi->param('action') || '';
	my $setcookie;

	if ($action eq $defaults{button_login}) { 
		if (authorized_admin($cgi->param('user'), $cgi->param('pass'))) {
			my $expire = strftime($cookie_time_fmt, gmtime(time + 86400*30));
			$setcookie = CGI::Cookie->new(
				-name	=> 'admin',
				-value	=> $cgi->param('user') 
					. ':'
					. md5_hex($qd->{random_token} . $cgi->param('user') . $ENV{REMOTE_ADDR}),
				-expires	=> $expire,
			);
			$authorized = $cgi->param('user');
			print $cgi->header(-cookie => $setcookie);
		} else {
			$args{error} = "Invalid login";
			$args{message} = "We're logging your IP address";
			print STDERR "Bad admin password guess for ".$cgi->param('user')." from $ENV{REMOTE_ADDR}\n";
		}
	} elsif ($action eq $defaults{button_logout}) {
		print $cgi->header(-cookie => CGI::Cookie->new(
			-name		=> 'admin',
			-value		=> 'nope',
		));
		%cookies = ();
	}

	unless ($setcookie) {
		print $cgi->header();

		if ($cookies{admin}) {
			my $v = $cookies{admin}->value();
			$v =~ m/^([^:]+):(.*)/;
			my $u = $1;
			my $md5 = $2;
			my $verify = md5_hex($qd->{random_token} . $u . $ENV{REMOTE_ADDR});
			if ($md5 eq $verify) {
				$authorized = $u;
			} elsif ($v ne 'nope') {
				$args{error} = "Invalid login cookie";
				$args{message} = "Please log in again";
				print STDERR "Invalid admin cookie for $u from $ENV{REMOTE_ADDR}\n";
			} 
		}
	}

	my $email = $cgi->param('lookupemail') || CGI::unescape($cgi->param('adminemail'));

	if ($authorized && $email) {
		$args{email} = $email;

		$args{hiddenstate} = qq{<input type="hidden" name="adminemail" value="$escape{$email}">};
		$args{adminemail} = $escape{$email};

		my $psender = $qd->{senders}{$email};
		if ($psender) {
			$args{psender} = $psender;
			$args{sender} = $psender;
			$args{otherheaders} = [ grep(! $_->{done}, values %{$psender->{headers}}) ];
			$args{sender_url} = $psender->url;
		}

		my $rd = $qd->{recipients}{$email};
		if ($rd) {
			$args{rd} = $rd;
			$args{recipient} = $email;
			$args{recipient_url} = $rd->url($qd);
		}

		if ($action eq $defaults{button_lookup_email}) {
			# nothing
		} else {
			for my $button (keys %defaults) {
				next unless $button =~ /^button_/;
				next unless $action eq $defaults{$button};
				print STDERR "Button $button pressed\n";
				if ($button =~ /sender/) {
					(my $docommit, undef, my @message) = sender_action($oops, $email, $psender, $action, \%args, 0);
					$oops->commit() if $docommit;
					$args{smessage} = message('Sender', @message);
					last;
				} elsif ($button =~ /recipient/) {
					(undef, my @message) = recipient_action($oops, $email, $rd, \%args, 0, $action);
					$args{rmessage} = message('Recipient', @message);
					last;
				}
			}
		}
	}

	$args{authorized} = $authorized;
	$template->process('admin.tt2', \%args) || error $Template::ERROR;
	return;
}

sub message
{
	my ($role, @message) = @_;
	return "" unless @message;
	print STDERR "## $role: @message\n";
	return "<p>\n".join("\n</p><p>\n", @message)."\n</p>\n";
}


sub send_queued
{
	my ($to, @list) = @_;
	for my $m (@list) {
		sendmail_or_postpone(
			from	=> ($m->{sender} || '<>'),
			to	=> $m->{to},
			header	=> $m->{header},
			body	=> $m->{body},
		);
	}
}

sub authorized_admin
{
	my ($user, $pass) = @_;
	return 0 unless $user =~ /^\w/;
	open(PWFILE, "<$defaults{admin_passwd_file}") || error;
	while(<PWFILE>) {
		next if /^$/;
		next if /^#/;
		chomp;
		my ($u, $p) = split(':', $_);
		next if $u ne $user;
		return 1 if crypt($pass, $p) eq $p;
		printf STDERR "Attempted login: %s '%s' ne '%s'\n", $pass, $p, crypt($pass, $p);
		return 0;
	}
	close(PWFILE);
	print STDERR "User $user not found in password file\n";
	return 0;
}

my %filter_domains;
sub domain_is_filtered
{
	my ($domain) = @_;
	unless (%filter_domains) {
		open(DOMS, "<$filtered_domains") || error "open $filtered_domains: $!";
		while(<DOMS>) {
			next if /^#/;
			next if /^$/;
			chomp;
			$filter_domains{$_} = 1;
		}
		close(DOMS);
	}
	return match_domain($domain, \%filter_domains);
}

sub match_domain
{
	my ($domain, $hashref) = @_;
	while ($domain) {
		if ($hashref->{$domain}) {
			return 1;
		} 
		$domain =~ s/^[^\.]+// or last;
		$domain =~ s/^\.//;
	}
	return 0;
}

# for the benifit of the Template module...

sub Quarantine::Sender::cookie
{
	my ($sender) = @_;
	return "foo";
}

1;
