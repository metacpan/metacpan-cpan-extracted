#!/usr/bin/perl

package RT::Action::SMSNotify;
use 5.10.1;
use strict;
use warnings;

use Data::Dumper;
use SMS::Send;

use base qw(RT::Action);

=pod

=head1 NAME

RT::Action::SMSNotify

=head1 DESCRIPTION

See L<RT::Extension::SMSNotify> for details on how to use this extension,
including how to customise error reporting.

This action may be invoked directly, from rt-crontool, or via a Scrip.

=head1 ARGUMENTS

C<RT::Action::SMSNotify> takes a single argument, like all other RT actions.
The argument is a comma-delimited string of codes indicating where the module
should get phone numbers to SMS from. Wherever a group appers in a category,
all the users from that group will be recursively added.

Recognised codes are:

=head2 TicketRequestors

The ticket requestor(s). May be groups.

=head2 TicketCc

All entries in the ticket Cc field

=head2 TicketAdminCc

All entires in the ticket AdminCc field

=head2 TicketOwner

The ticket Owner field

=head2 QueueCc

All queue watchers in the Cc category on the queue

=head2 QueueAdminCc

All queue watchers in the AdminCc category on the queue

=head2 g:name

The RT group with name 'name'. Ignored with a warning if it doesn't exist.
No mechanism for escaping commas in names is provided.

=head2 p:number

A phone number, specified in +0000000 form with no spaces, commas etc.

=head2 filtermodule:

You may override the phone number filter function on a per-call basis by
passing filtermodule: in the arguments. The argument must be the name of a
module that defines a GetPhoneForUser function.

This can appear anywhere in the argument string. For example, to force
the use of the OnShift filter for this action, you might write:

 TicketAdminCc,TicketRequestors,TicketOwner,TicketCc,filtermodule:RT::Extension::SMSNotify::OnShift

=cut

sub _ArgToUsers {
	# Convert one of the argument codes into an array of users.
	# If it's one of the predefined codes, looks up the users object for it;
	# otherwise looks for a u: or g: prefix for a user or group name or
	# for a p: prefix for a phone number.
	#
	# returns a 2-tuple where one part is always undef. 1st part is
	# arrayref of RT::User objects, 2nd part is a phone number from a p:
	# code as a string.
	#
	my $ticket = shift;
	my $name = shift;
	my $queue = $ticket->QueueObj;
	# To be set to an arrayref of members
	my $m = undef;
	# To be set to a scalar phone number from p:
	my $p = undef;
	RT::Logger->debug("SMSNotify: Examining $name for recipients");
	for ($name) {
		when (/^TicketRequestors?$/) {
			$m = $ticket->Requestors->UserMembersObj->ItemsArrayRef;
		}
		when (/^TicketCc$/) {
			$m = $ticket->Cc->UserMembersObj->ItemsArrayRef;
		}
		when (/^TicketAdminCc$/) {
			$m = $ticket->AdminCc->UserMembersObj->ItemsArrayRef;
		}
		when (/^TicketOwner$/) {
			$m = $ticket->OwnerGroup->UserMembersObj->ItemsArrayRef;
		}
		when (/^QueueCc$/) {
			$m = $queue->Cc->UserMembersObj->ItemsArrayRef;
		}
		when (/^QueueAdminCc$/) {
			$m = $queue->AdminCc->UserMembersObj->ItemsArrayRef;
		}
		when (/^g:/) { 
			my $g = RT::Group->new($RT::SystemUser);
			$g->LoadUserDefinedGroup(substr($name,2));
			$m = $g->UserMembersObj->ItemsArrayRef;
		}
		when (/^p:/) { $p = substr($name, 2); }
		default {
			RT::Logger->error("Unrecognised argument $name, ignoring");
		}
	}
	die("Assertion that either \$m or \$p is undef violated") if (defined($m) == defined($p));
	if (defined($m)) {
		my @recips =  map $_->Name, grep defined, @$m;
		RT::Logger->debug("SMSNotify: Found " . scalar(@recips) . " recipient(s): " . join(', ', @recips) );
	} else {
		RT::Logger->debug("SMSNotify: Found phone number $p");
	}
	return $m, $p;
}

sub _AddPagersToRecipients {
	# Takes hashref of { userid => userobject } form and an arrayref of
	# RT::User objects to merge into it if the user ID isn't already
	# present.
	my $destusers = shift;
	my $userstoadd = shift;
	for my $u (@$userstoadd) {
		$destusers->{$u->Id} = $u;
	}
}

sub Prepare {
	my $self = shift;

	if (!$self->Argument) {
		RT::Logger->error("Argument to RT::Action::SMSNotify required, see docs");
		return 0;
	}

	if (! RT->Config->Get('SMSNotifyArguments') ) {
		RT::Logger->error("\$SMSNotifyArguments is not set in RT_SiteConfig.pm");
		return 0;
	}

	if (!defined(RT->Config->Get('SMSNotifyProvider'))) {
		RT::Logger->error("\$SMSNotifyProvider is not set in RT_SiteConfig.pm");
		return 0;
	}

	my $ticket = $self->TicketObj;
	my $destusers = {};
	my %numbers = ();
	my $filter_arg = undef;
	foreach my $argpart (split(',', $self->Argument)) {
		if ($argpart =~ /filtermodule:/) {
			$filter_arg = substr($argpart,length("filtermodule:"));
		} else {
			my ($userarray, $phoneno) = _ArgToUsers($ticket, $argpart);
			_AddPagersToRecipients($destusers, $userarray) if defined($userarray);
			$numbers{$phoneno} = undef if defined($phoneno);
		}
	}
	if ($filter_arg) {
		RT::Logger->debug("SMSNotify: Using phone filter argument " . $filter_arg);
	}
	# For each unique user to be notified, get their phone number(s) using
	# the $SMSNotifyGetPhoneForUserFn mapping function and if it's defined,
	# add that number as a key to the numbers hash with their user ID as the value.
	# (If multiple users have the same number, the last user wins).
	RT::Logger->debug("SMSNotify: Checking users for pager numbers: " . join(', ', map $_->Name, values %$destusers) );

	my $getpagerfn = RT::Extension::SMSNotify::_GetPhoneLookupFunction($filter_arg);
	foreach my $u (values %$destusers) {
		foreach my $ph (&{$getpagerfn}($u, $ticket)) {
			if (defined($ph)) {
				RT::Logger->debug("SMSNotify: Adding $ph for user " . $u->Name);
			} else {
				RT::Logger->debug("SMSNotify: GetPhoneForUser function returned undef for " . $u->Name . ", skipping");
			}
			$numbers{$ph} = $u if ($ph);
		}
	}

	if (%numbers) {
		RT::Logger->info("SMSNotify: Preparing to send SMSes to: " . join(', ', keys %numbers) );
	} else {
		RT::Logger->info("SMSNotify: No recipients with pager numbers, not sending SMSes");
	}

	$self->{'PagerNumbersForUsers'} = \%numbers;

	return scalar keys %numbers;
}

sub Commit {

	my $self = shift;

	my %memberlist = %{$self->{'PagerNumbersForUsers'}};

	my $cfgargs = RT->Config->Get('SMSNotifyArguments');
	my $smsprovider = RT->Config->Get('SMSNotifyProvider');

	my $sender = SMS::Send->new( $smsprovider, %$cfgargs );
	while ( my ($ph,$u) = each %memberlist ) {

		my $uname = defined($u) ? $u->Name : 'none';

		my ($result, $message) = $self->TemplateObj->Parse(
			Argument       => $self->Argument,
			TicketObj      => $self->TicketObj,
			TransactionObj => $self->TransactionObj,
			UserObj        => $u,
                        PhoneNumber    => $ph
		);
		if ( !$result ) {
			eval {
				RT::Extension::SMSNotify::_GetErrorNotifyFunction()->($result, $message, $ph, $u);
			};
			if ($@) { RT::Logger->crit("SMSNotify: Error notify function died: $@"); }
			next;
		}

		my $MIMEObj = $self->TemplateObj->MIMEObj;
		my $msgstring = $MIMEObj->bodyhandle->as_string;

		eval {
			$RT::Logger->debug("SMSNotify: Sending SMS to $ph");
			$sender->send_sms(
				text => $msgstring,
				to   => $ph
			);
			$RT::Logger->info("SMSNotify: Sent SMS to $ph (user: $uname)");
		};
		if ($@) {
			my $msg = $@;
			eval {
				my $errfn = RT::Extension::SMSNotify::_GetErrorNotifyFunction();
				$errfn->($result, $msg, $ph, $u);
			};
			if ($@) { RT::Logger->crit("SMSNotify: Error notify function died: $@"); }
		}
	}

	return 1;
}

1;

