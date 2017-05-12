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

package Qpsmtpd::Plugin::Quarantine::Sendmail;

use Mail::SendVarious;
use Mail::SendVarious qw(@to_rejected $mail_error);
use Qpsmtpd::Plugin::Quarantine::Common;
use OOPS;
use Time::HiRes qw(time);
require Exporter;
use strict;

our @ISA = qw(Exporter);
our @EXPORT = qw(sendmail_or_queue sendmail_or_postpone send_postponed);

our @postponed;

sub sendmail_or_postpone
{
	my (%options) = @_;
	if (sendmail(%options)) {
		return 1 unless @to_rejected;
		$options{to} = [ @to_rejected ];
	}
	push(@postponed, \%options);
}

sub send_postponed
{
	while (@postponed) {
		sendmail_or_queue(%{shift(@postponed)});
	}
}

sub sendmail_or_queue
{
	my (%options) = @_;
	if (sendmail(%options)) {
		return 1 unless @to_rejected;
		$options{to} = [ @to_rejected ];
	}
	for my $o (keys %options) {
		delete $options{$o} if ref($options{$o}) eq 'CODE';
	}
	$options{first_attempt} = time;
	$options{attempt_count} = 1;
	$options{last_attempt} = time;
	$options{last_error} = $mail_error;
	my $options = \%options;
	bless $options, 'Quarantine::QueuedMail';
	transaction(sub {
		my $oops = get_oops();
		my $qd = $oops->{quarantine};
		my $mqueue = $qd->{mqueue};
		$mqueue->{$$.time()} = $options;
		$oops->commit();
	});
}

1;
