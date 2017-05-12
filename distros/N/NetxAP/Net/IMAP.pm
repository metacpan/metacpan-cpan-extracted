#!/usr/local/bin/perl
#
# Copyright (c) 1997-1999 Kevin Johnson <kjj@pobox.com>.
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: IMAP.pm,v 1.2 1999/10/03 14:56:21 kjj Exp $

require 5.005;

package Net::IMAP;

use strict;

=head1 NAME

Net::IMAP - A client interface to IMAP (Internet Message Access Protocol).

B<WARNING: This code is in alpha release.  Expect the interface to
change release to release.>

=cut

use Net::xAP;
use Carp;
use MIME::Base64;
use Digest::HMAC_MD5 qw(hmac_md5 hmac_md5_hex);

use vars qw($VERSION @ISA $AUTOLOAD);

$VERSION = "0.02";

@ISA = qw(Net::xAP);

use constant ATOM => Net::xAP::ATOM;
use constant ASTRING => Net::xAP::ASTRING;
use constant PARENS => Net::xAP::PARENS;
use constant SASLRESP => Net::xAP::SASLRESP;

=head1 SYNOPSIS

C<use Net::IMAP;>

=head1 DESCRIPTION

C<Net::IMAP> provides a perl interface to the client portion of IMAP
(Internet Message Access Protocol).

B<add more meat - describe overall design (commands, responses,
callbacks, convenience routines>

=head1 METHODS

=cut

use constant IMAP_STATE_NOT_AUTH => 1;
use constant IMAP_STATE_AUTH => 2;
use constant IMAP_STATE_SELECT => 4;
use constant IMAP_STATE_ANY => 7;

my %untagged_callbacks = (
			  'ok' => [\&_default_aux_callback],
			  'bye' => [\&_default_aux_callback],
			  'bad' => [\&_default_aux_callback],
			  'no' => [\&_default_aux_callback],
			  'capability' => [undef],
			  'list' => [undef],
			  'lsub' => [undef],
			  'status' => [undef],
			  'search' => [undef],
			  'flags' => [undef],
			  'exists' => [undef],
			  'recent' => [undef],
			  'expunge' => [undef],
			  'fetch' => [undef],
			  'namespace' => [undef],
			  'acl' => [undef],
			  'listrights' => [undef],
			  'myrights' => [undef],
			  'quota' => [undef],
			  'quotaroot' => [undef],
			 );

my %cmd_callbacks = (
		     'noop' => [undef, IMAP_STATE_ANY],
		     'capability' => [undef, IMAP_STATE_ANY],
		     'logout' => [undef, IMAP_STATE_ANY],
		     'authenticate' => ['_login_cmd_callback',
					IMAP_STATE_NOT_AUTH],
		     'login' => ['_login_cmd_callback', IMAP_STATE_NOT_AUTH],
		     'select' => ['_select_cmd_callback',
				  IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'examine' => ['_select_cmd_callback',
				   IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'create' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'delete' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'rename' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'subscribe' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'list' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'lsub' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'status' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'append' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'check' => [undef, IMAP_STATE_SELECT],
		     'close' => ['_close_cmd_callback', IMAP_STATE_SELECT],
		     'expunge' => [undef, IMAP_STATE_SELECT],
		     'search' => [undef, IMAP_STATE_SELECT],
		     'fetch' => [undef, IMAP_STATE_SELECT],
		     'store' => [undef, IMAP_STATE_SELECT],
		     'copy' => [undef, IMAP_STATE_SELECT],
		     'uid copy' => [undef, IMAP_STATE_SELECT],
		     'uid fetch' => [undef, IMAP_STATE_SELECT],
		     'uid search' => [undef, IMAP_STATE_SELECT],
		     'uid store' => [undef, IMAP_STATE_SELECT],
		     # Extension commands:
		     'namespace' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'setacl' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'getacl' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'deleteacl' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'listrights' => [undef,
				      IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'myrights' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'getquota' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'setquota' => [undef, IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'getquotaroot' => [undef,
					IMAP_STATE_AUTH|IMAP_STATE_SELECT],
		     'uid expunge' => [undef, IMAP_STATE_SELECT],
		    );

my %_system_flags = (
		     '\seen' => 1,
		     '\answered' => 1,
		     '\flagged' => 1,
		     '\deleted' => 1,
		     '\draft' => 1,
		     '\recent' => 1,
		    );

=head2 new $host, %options

Creates a new C<Net::IMAP> object, connects to C<$host> on port 143,
performs some preliminary setup of the session, and returns a
reference to the object.

Once connected, it processes the connection banner sent by the server.
If the considers the session to be preauthenticated, C<new> notes the
fact, allowing commands to be issued without logging in.

The method also issues a C<capability> command, and notes the result.
If the server does support IMAP4rev1, the method closes the connection
and returns C<undef>.

The client will use non-synchronizing literals if the server supports
the C<LITERAL+> extension (RFC2088) and the C<NonSyncLits> options is
set to C<1>.

The following C<Net::xAP> options are relevant to C<Net::IMAP>:

=over 4

=item C<Synchronous =E<gt> 1>

=item C<NonSyncLits =E<gt> 0>

=item C<Debug =E<gt> 0>

=item C<InternetDraft =E<gt> 0>

=back

C<Net::IMAP> also understands the following options, specific to the module:

=over 4

=item C<EOL =E<gt> 'lf'>

Controls what style of end-of-line processing to presented to the
end-programmer.  The default, C<'lf'>, assumes that the programemr
wants to fling messages terminated with bare LFs when invoking append,
and when fetching messages.  In this case, the module will map to/from
CRLF accordingly.

If C<EOL> is set to C<'crlf'>, the assumption is that the programmer
wants messages, or portions of messages, to be terminated with CRLF.
It also assumes the programmer is providing messages terminated with
the string when invoking the C<append> method, and will not provide an
EOL mapping.

=back

=cut

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $host = shift if @_ % 2;
  my %options = @_;

  my $self = Net::xAP->new($host, 'imap2(143)', Timeout => 10, %options)
    or return undef;

  bless $self, $class;

  $self->{Options}{EOL} ||= 'lf';
  $self->{Options}{EOL} = lc($self->{Options}{EOL}); # force lower-case

  $self->{PreAuth} = 0;
  $self->{Banner} = undef;
  $self->{Capabilities} = ();
  $self->_init_mailbox;
  $self->{Disconnect} = 0;
  $self->{State} = IMAP_STATE_NOT_AUTH;

  $self->{ResponseCallback} = $self->imap_response_callback;

  STDERR->autoflush(1);

  $self->_get_banner or return undef;

  # the little back-flip here with the Synchronous option ensures that
  # the capability command is issued in Synchronous mode

  my $mode = $self->{Options}{Synchronous}; # save current sync mode
  $self->{Options}{Synchronous}++; # force sync mode on
  my $resp = $self->capability;
  $self->{Options}{Synchronous} = $mode; # restore previous sync mode

  if ($resp->status ne 'ok') {
    carp "capability command failed on initial connection";
    $self->close_connection or carp "error closing connection: $!";
    $! = 5;			# *sigh* error reporting needs to be improved
    return undef;
  }

  return $self;
}

sub _init_mailbox {
  my $self = shift;
  $self->{Mailbox} = '';
  $self->{MailboxStatus} = ();
  $self->{MailboxStatus}{'recent'} = 0;
  $self->{MailboxStatus}{'unseen'} = 0;
  $self->{MailboxStatus}{'exists'} = 0;
  $self->{MailboxStatus}{'uidvalidity'} = 0;
  $self->{MailboxStatus}{'uidnext'} = 0;
  $self->{MailboxStatus}{'flags'} = ();
}

sub debug_text { $_[2] =~ /^(\d+ LOGIN [^\s]+)/i ? "$1 ..." : $_[2] }

sub _get_banner {
  my $self = shift;
  my $str = $self->getline;

  my $list = $self->parse_fields($str);
  return undef unless defined($list);

  if (($list->[0] eq '*') && ($list->[1] =~ /^preauth$/i)) {
    $self->{PreAuth}++;
    $self->{State} = IMAP_STATE_AUTH;
  } elsif (($list->[0] ne '*') || ($list->[1] !~ /^ok$/i)) {
    return undef;
  }
  my $supports_imap4rev1 = 0;
  for my $item (@{$list}) {
    $supports_imap4rev1++ if ($item =~ /^imap4rev1$/i);
  }
  unless ($supports_imap4rev1) {
    $self->close_connection;
    return undef;
  }

  $self->{Banner} = $list;

  return 1;
}

sub DESTROY {
  my $self = shift;
}

sub AUTOLOAD {
  my $self = shift;
  my $cmd = $AUTOLOAD;
  $cmd =~ s/^.*:://;
  carp("unknown command: $cmd");
  return undef;
}

###############################################################################

=head1 IMAP COMMAND METHODS

There are numerous commands in the IMAP protocol.  Each of these are
mapped to a corresponding method in the C<Net::IMAP> module.

Some commands can only be issued in certain protocol states.  Some
commands alter the state of the session.  These facts are indicated in
the documentation for the individual command methods.

The following list enumerates the protocol states:

=over 4

=item Non-authenticated

The client has not authenticated with the server.  Most commands are
unavailable in this state.

=item Authenticated

The client has authenticated with the server.

=item Selected

The client has opened a mailbox on the server.

=back

=head2 noop

Sends a C<noop> command to the server.  It is valid in any protocol state.

This method is useful for placating the auto-logout god, or for
triggering pending unsolicited responses from the server.

=cut

sub noop { $_[0]->imap_command('noop') }

=head2 capability

The C<capability> method retrieves the capabilities the IMAP server
supports.  This method is valid in any protocol state.

The server sends a C<capability> response back to the client.

If the response does not indicate support for the C<LITERAL+>
extension, the C<NonSyncLits> option is forced off.

=cut

sub capability { $_[0]->imap_command('capability') }

=head2 logout

Logs off of the server.  This method is valid in any protocol state.

=cut

sub logout {
  $_[0]->{Disconnect}++;
  $_[0]->imap_command('logout');
}

=head2 login $user, $password

Logs into the server using a simple plaintext password.  This method
is only valid when the protocol is in the non-authenticated state.

If the server supports RFC2221 (IMAP4 Login Referrals), the completion
response could include a referral.  See RFC2221 for further
information about login referrals.

If successful, the session state is changed to I<authenticated>.

=cut

sub login { $_[0]->imap_command('login', ASTRING, $_[1], ASTRING, $_[2]) }

=head2 authenticate $authtype, @authinfo

Logs into the server using the authentication mechanism specified in
C<$authtype>.  This method is only valid when the protocol is in the
non-authenticated state.

The IMAP C<authenticate> command is the same as that documented in
RFC2222 (Simple Authentication and Security Layer (SASL)), despite the
fact that IMAP predates SASL.

If successful, the session state is changed to I<authenticated>.

The following authentication mechanisms are currently supported:

=over 4

=item C<'login'>

This is a variation on the simple login technique, except that the
information is transmitted in Base64.  This does not provide any
additional security, but does allow clients to use C<authenticate>.

=item C<'cram-md5'>

This implements the authentication mechanism defined in RFC2195
(IMAP/POP AUTHorize Extension for Simple Challenge/Response).  It uses
keyed MD5 to avoid sending the password over the wire.

=item C<'anonymous'>

This implements the authentication mechanism defined in RFC2245
(Anonymous SASL Mechanism).  Anonymous IMAP access is intended to
provide access to public mailboxes or newsgroups.

=back

The method returns C<undef> is C<$authtype> specifies an unsupported
mechanism or if the server does not advertise support for the
mechanism.  The C<has_authtype> method can be used to see whether the
server supports a particular authentication mechanism.

In general, if the server supports a mechanism supported by
C<Net::IMAP>, the C<authenticate> command should be used instead of
the C<login> method.

=cut

my %auth_funcs = (
  'LOGIN' => \&authenticate_login,
  'CRAM-MD5' => \&authenticate_cram,
  'ANONYMOUS' => \&authenticate_anonymous,
);

my @auth_strings;

sub authenticate {
  my $authtype = uc($_[1]);
  return undef unless defined($auth_funcs{$authtype});
  return undef unless defined($_[0]->has_authtype($authtype));
  my $func = $auth_funcs{$authtype};
  @auth_strings = @_[2..$#_];
  $_[0]->imap_command('authenticate',
		      ATOM, $authtype,
		      SASLRESP, $func);
}

sub authenticate_login {
  my $i = shift;

  return undef unless defined($auth_strings[$i]);
  return encode_base64($auth_strings[$i], '');
}

sub authenticate_cram {
  my $i = shift;
  my $challenge = shift;

  if ($i == 0) {
    $challenge = decode_base64($challenge);
    $challenge = hmac_md5_hex($challenge, $auth_strings[1]);
    $auth_strings[1] = undef;
    return(encode_base64("$auth_strings[0] $challenge", ''));
  }
  return undef;
}

sub authenticate_anonymous {
  my $i = shift;
  return(encode_base64(join(' ', @auth_strings), '')) if ($i == 0);
  return undef;
}

=head2 select $mailbox

Opens the specified mailbox with the intention of performing reading
and writing.  This method is valid only when the session is in the
authenticated or selected states.

If successful, the server sends several responses: C<flags>,
C<exists>, C<resent>, as well as C<ok> responses containing a
C<unseen>, C<permanentflags>, C<uidnext>, and C<uidvalidity> codes.
If also changes the session state to I<selected>.

If server returns a C<no> response containing a C<newname> response
code, this means C<$mailbox> does not exist but the server thinks this
is because the folder was renamed.  In this case, try specifiying the
new folder name provided with the C<newname> response code.

=cut

sub select {
  $_[0]->{Mailbox} = $_[1];
  my $ret = $_[0]->imap_command('select', ASTRING, _encode_mailbox($_[1]));
  $_[0]->{Mailbox} = '' unless defined($ret);
  return $ret;
}

=head2 examine $mailbox

Opens the specified mailbox in read-only mode.  This method is valid
only when the session is in the authenticated or selected states.

=cut

sub examine { $_[0]->imap_command('examine', ASTRING, _encode_mailbox($_[1])) }

=head2 create $mailbox [, $partition]

Creates the specified mailbox.  This method is valid only when the
session is in the authenticated or selected states.

The optional C<$partition> argument is only valid with the Cyrus IMAP
daemon.  Refer to the section 'Specifying Partitions with "create"'
the C<doc/overview> file for that package for further information.
This feature can only be used by administrators creating new
mailboxes.  Other servers will probably reject the command if this
argument is used.  The results are undefined if another server accepts
a second argument.

=cut

sub create {
  my @args = (ASTRING, _encode_mailbox($_[1]));
  push @args, ATOM, $_[2] if (defined($_[2]));
  $_[0]->imap_command('create', @args);
}

=head2 delete $mailbox

Deletes the specified mailbox.  Returns C<undef> if C<$mailbox> is the
currently open mailbox.  This method is valid only when the session is
in the authenticated or selected states.

=cut

sub delete {
  return undef if ($_[0]->{Mailbox} eq $_[1]);
  $_[0]->imap_command('delete', ASTRING, _encode_mailbox($_[1]));
}

=head2 rename $oldmailboxname, $newmailboxname [, $partition]

Renames the mailbox specified in C<$oldmailbox> to the name specified
in C<$newmailbox>.  This method is valid only when the session is in
the authenticated or selected states.

The optional C<$partition> argument is only valid with the Cyrus IMAP
daemon.  Refer to the section 'Specifying Partitions with "rename"'
the C<doc/overview> file for that package for further information.
This feature can only be used by administrators.  Other servers will
probably reject the command if this argument is used.  The results are
undefined if another server accepts a third argument.

=cut

sub rename {
  my @args = (ASTRING, _encode_mailbox($_[1]), ASTRING, _encode_mailbox($_[2]));
  push @args, ATOM, $_[3] if defined($_[3]);
  $_[0]->imap_command('rename', @args);
}

=head2 subscribe $mailbox

Subscribe to the specified C<$mailbox>.  Subscribing in IMAP is
subscribing in Usenet News, except that the server maintains the
subscription list.  This method is valid only when the session is in
the authenticated or selected states.

=cut

sub subscribe { $_[0]->imap_command('subscribe',
				    ASTRING, _encode_mailbox($_[1])) }

=head2 unsubscribe $mailbox

Unsubscribe from the specified C<$mailbox>.  This method is valid only
when the session is in the authenticated or selected states.

=cut

sub unsubscribe { $_[0]->imap_command('unsubscribe',
				      ASTRING, _encode_mailbox($_[1])) }

=head2 list $referencename, $mailbox_pattern

Send an IMAP C<list> command to the server.  This method is valid only
when the session is in the authenticated or selected states.

Although IMAP folders do not need to be implemented as directories,
think of an IMAP reference name as a parameter given to a C<cd> or
C<chdir> command, prior to checking for folders matching
C<$mailbox_pattern>.

The C<$mailbox_pattern> parameter allows a couple wildcard characters
to list subsets of the mailboxes on the server.

=over 4

=item *

Matches zero or more characters at the specified location.

=item %

Like C<*>, matches zero or more characters at the specified location,
but does not match hierarchy delimiter characters.

If the last character in C<$mailbox_pattern> is a C<%>, matching
levels of hierarchy are also returned.  In other words: subfolders.

=back

This method will fail, returning C<undef>, if C<$mailbox_pattern> is
C<*>.  This behavior is not built into the IMAP protocol; it is wired
into C<Net::IMAP>.  Doing otherwise could be rude to both the client
and server machines.  If you want to know why, imagine doing
C<list('#news.', '*')> on a machine with a full news feed.  The C<%>
character should be used to build up a folder tree incrementally.

If successful, the server sends a series of C<list> responses.

Please note that the C<$referencename> is an IMAPism, not a Perl
reference.  Also note that the wildcards usable in C<$mailbox_pattern>
are specific to IMAP.  Perl regexps are not usable here.

=cut

sub list {
  return undef if ($_[2] eq '*');
  $_[0]->imap_command('list',
		      ASTRING, _encode_mailbox($_[1]),
		      ASTRING, _encode_mailbox($_[2]));
}

=head2 lsub $referencename, $mailbox_pattern

Sends an IMAP C<lsub> command to the server.  The C<lsub> command is
similar to the C<list> command, except that the server only returns
subscribed mailboxes.  This method is valid only when the session is
in the authenticated or selected states.

The parameters are the same as those for the C<list> method.

If successful, the server sends a series of C<lsub> responses.

=cut

sub lsub { $_[0]->imap_command('lsub',
			       ASTRING, _encode_mailbox($_[1]),
			       ASTRING, _encode_mailbox($_[2])) }

=head2 status $mailbox, @statusattrs

Retrieves status information for the specified C<$mailbox>.  This
method is valid only when the session is in the authenticated or
selected states.

Per RFC2060, the C<@statusattrs> can contain any of the following
strings:

=over 4

=item * messages

The number of messages in the mailbox.

=item * recent

The number of messages with the C<\recent> flag set.

=item * uidnext

The UID expected to be assigned to the next mailbox appended to the
mailbox.  This requires some explanation.  Rather than using this
value for prefetching the next UID, it should be used to detect
whether messages have been added to the mailbox.  The value will not
change until messages are appended to the mailbox.

=item * uidvalidity

The unique identifier validity value of the mailbox.

=item * unseen

The number of messages without the C<\seen> flag set.

=back

This method will fail, returning C<undef> if C<$mailbox> is the
currently open mailbox.

If successful, the server sends one or more C<status> responses.

The status operation can be rather expensive on some folder
implementations, so clients should use this method sparingly.

=cut

sub status {
  my $self = shift;
  my $mailbox = shift;
  return undef if ($self->{Mailbox} eq $mailbox);
  $self->imap_command('status',
		      ASTRING, _encode_mailbox($mailbox), PARENS, [@_]);
}

=head2 append $mailbox, $message [, Flags => $flaglistref] [, Date => $date]

Appends the email message specified in C<$message> to the mailbox
specified in C<$mailbox>.  This method is valid only when the session
is in the authenticated or selected states.

In general, the email message should be a real RFC822 message,
although exceptions such as draft messages are reasonable in some
situations.  Also note that the line terminators in C<$message> need
to be CRLF.

The C<Flags> option allows a set of flags to be specified for the
message when it is appended.  Servers are not required to honor this,
but most, if not all, do so.

The C<Date> option forces the internaldate to the specified value.  If
C<$date> is a string, the format of the string is C<dd-mmm-yyyy
hh:mm:ss [-+]zzzz>, where C<dd> is the day of the month (starting from
1), C<mmm> is the three-character abbreviation for the month name,
C<yyyy> is the 4-digit year, C<hh> is the hour, C<mm> is the minutes,
C<ss> is the seconds, and C<[-+]zzzz> is the numeric timezone offset.
This happens to be the same format returned by the C<internaldate>
item from the C<fetch> command.  If C<$date> is a list reference, it is
expected to contain two elements: a time integer and a timezone offset
string.  The timezone string is expected to be formatted as
C<[-+]zzzz>.  These two values will be used to synthesize a string in
the format expected by the IMAP server.  As with the C<Flags> options,
servers are not required to honor the C<Date> option, but most, if not
all, do so.

Note that the options are specified at the end of the list of method
arguments.  This is due to the fact that it is possible to have a
C<$mailbox> named C<Flags> or C<Date>.  Processing the options at the
end of the argument list simplifies argument processing.  The order of
the arguments will be changed if enough people complain.

If server returns a C<no> response containing a C<trycreate> response
code, this means C<$mailbox> does not exist but the server thinks the
command would have succeeded if the an appropriate C<create> command
was issued.  On the other hand, failure with no C<trycreate> response
code generally means that a C<create> should not be attempted.

=cut

sub append {
  my $self = shift;
  my $mailbox = shift;
  my $lit = shift;
  my %options = @_;
  my @args;

  push @args, ASTRING, _encode_mailbox($mailbox);

  if (defined($options{Flags})) {
    for my $flag (@{$options{Flags}}) {
      unless ($self->_valid_flag($flag)) {
	carp "$flag is not a system flag";
	return undef;
      }
    }
    push @args, PARENS, [@{$options{Flags}}];
  }
  if (defined($options{Date})) {
    my $date;
    if ((ref($options{Date}) eq 'ARRAY')
	&& defined($options{Date}->[1])){
      my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
      my @gmtime = gmtime($options{Date}->[0]);
      $date = sprintf("%02d-%2s-%4d %02d:%02d:%02d %s",
		      $gmtime[3], $months[$gmtime[4]], $gmtime[5] + 1900,
		      $gmtime[2], $gmtime[1], $gmtime[0],
		      $options{Date}->[1]);
    } else {
      $date = $options{Date};
    }
    if ($date !~ /^[ \d][\d]-[a-zA-Z]{3}-\d{4} \d\d:\d\d:\d\d [\+\-]\d{4}$/) {
      carp "invalid date value for append command";
      return undef;
    }
    push @args, ATOM, "\"$date\"";
  }
  $lit =~ s/\n/\r\n/mg if ($self->{Options}{EOL} eq 'lf');
  push @args, ASTRING, $lit;

  $self->imap_command('append', @args);
}

=head2 check

Ask the server to perform a checkpoint of its data.  This method is
valid only when the session is in the selected state.

While not always needed, this should be called if the client issues a
large quantity of updates to a folder in an extended session.

=cut

sub check { $_[0]->imap_command('check') }

=head2 close

Close the current mailbox.  This method is valid only when the session
is in the selected state.

If successful, the session state is changed to I<authenticated>.

=cut

sub close { $_[0]->imap_command('close') }

=head2 expunge

Delete messages marked for deletion.  This method is valid only when
the session is in the selected state.

If successful, the server sends a series of C<expunge> responses.

It will return C<undef> is the mailbox is marked read-only.

=cut

sub expunge {
  return undef if $_[0]->is_readonly;
  $_[0]->imap_command('expunge');
}

=head2 search [Charset => $charset,] @searchkeys

Searches the mailbox for messages matching the criteria contained in
C<@searchkeys>.  This method is valid only when the session is in the
selected state.

The C<@searchkeys> list contains strings matching the format described
in Section 6.4.4 of RFC2060.

If successful, the server send zero or more C<search> responses.  Lack
of a C<search> response means the server found no matches.  Note that
the server can send the results of one search in multiple responses.

=cut

sub search {
  my $self = shift;
  my @args;
  if ($_[0] =~ /^charset$/i) {
    shift;
    my $charset = shift;
    push @args, ATOM, 'charset', ASTRING, $charset;
  }
  push @args, map { (ATOM, $_) } @_;
  $self->imap_command('search', @args);
}

=head2 fetch $msgset, 'all'|'full'|'fast'|$fetchattr|@fetchattrs

Retrieves data about a set of messages.  This method is valid only
when the session is in the selected state.

The C<$msgset> parameter identifies the set of messages from which to
retrieve the items of interest.  The notation accepted is similar to
that found in C<.newsrc> files, except that C<:> is used to specify
ranges, instead of C<->.  Thus, to specify messages 1, 2, 3, 5, 7, 8,
9, the following string could be used: C<'1:3,5,7:9'>.  The character
C<*> can be used to indicate the highest message number in the
mailbox.  Thus, to specify the last 4 messages in an 8-message
mailbox, you can use C<'5-*'>.

The following list enumerates the items that can be retrieved with
C<fetch>.  Refer to Section 6.4.5 of RFC2060 for a description of each
of these items.

=over 4

=item * body[$section]E<lt>$partialE<gt>

=item * body.peek[$section]E<lt>$partialE<gt>

Important: the response item returned for a C<body.peek> is C<body>.

=item * bodystructure

=item * body

=item * envelope

=item * flags

=item * internaldate

=item * rfc822

=item * rfc822.header

=item * rfc822.size

=item * rfc822.text

=item * uid

=back

Please note that the items returning messages, or portion of messages,
return strings terminated with CRLF.

RFC2060 also defines several items that are actually macros for other
sets of items:

=over 4

=item * all

A macro equivalent to C<('flags', 'internaldate', 'rfc822.size', 'envelope')>.

=item * full

A macro equivalent to C<('flags', 'rfc822.size', 'envelope', 'body')>.

=item * fast

A macro equivalent to C<('flags', 'internaldate', 'rfc822.size')>.

=back

The C<all>, C<full>, and C<fast> items are not intended to be used
with other items.

If successful, the server responses with one or more C<fetch>
responses.

If the completion response from a C<fetch> command is C<no>, the
client should send a C<noop> command, to force any pending expunge
responses from the server, and retry the C<fetch> command with
C<$msgset> adjusted accordingly.

=cut

sub fetch {
  my $self = shift;
  my $msgset = shift;
  my @args;
  if (scalar(@_) == 1) {
    push @args, ATOM, shift;
  } else {
    push @args, PARENS, [@_];
  }
  $self->imap_command('fetch', ATOM, $msgset, @args);
}

=head2 store $msgset, $itemname, @storeattrflags

Sets various attributes for the messages identified in C<$msgset>.
This method is valid only when the session is in the selected state.

The C<$msgset> parameter is described in the section describing C<fetch>.

The C<$itemname> can be one of the following:

=over 4

=item * flags

Replaces the current flags with the flags specified in C<@storeattrflags>.

=item * +flags

Adds the flags specified in C<@storeattrflags> to the current flags.

=item * -flags

Removes the flags specified in C<@storeattrflags> from the current
flags.

=back

The C<$itemname> can also have C<.silent> appended, which causes the
server to not send back update responses for the messages.

If successful, and C<.silent> is used used in C<$itemname>, the server
response with a series of C<fetch> responses reflecting the updates to
the specified messages.

If the completion response from a C<store> command is C<no>, the
client should send a C<noop> command, to force any pending expunge
responses from the server, and retry the C<store> command with
C<$msgset> adjusted accordingly.

The C<@storeattrflags> is a list of flag strings.

=cut

sub store {
  my $self = shift;
  my $msgset = shift;
  my $itemname = shift;
  for my $flag (@_) {
    unless ($self->_valid_flag($flag)) {
      carp "$flag is not a system flag";
      return undef;
    }
  }
  $self->imap_command('store', ATOM, $msgset, ATOM, $itemname, PARENS, [@_]);
}

=head2 copy $msgset, $mailbox

Copy the messages C<$msgset> to the specified mailbox.  This method is
valid only when the session is in the selected state.

The C<$msgset> parameter is described in the section describing C<fetch>.

If server returns a C<no> response containing a C<trycreate> response
code, this means C<$mailbox> does not exist but the server thinks the
command would have succeeded if the an appropriate C<create> command
was issued.  On the other hand, failure with no C<trycreate> response
code generally means that a C<create> should not be attempted.

=cut

sub copy { $_[0]->imap_command('copy',
			       ATOM, $_[1], ASTRING, _encode_mailbox($_[2])) }

=head2 uid_copy $msgset, $mailbox

A variant of C<copy> that uses UIDs in C<$msgset>, instead of message
numbers.  This method is valid only when the session is in the
selected state.

=cut

sub uid_copy { $_[0]->imap_command('uid copy',
				   ATOM, $_[1],
				   ASTRING, _encode_mailbox($_[2])) }

=head2 uid_fetch $msgset, 'all'|'full'|'fast'|$fetchattr|@fetchattrs

A variant of C<fetch> that uses UIDs, instead of message numbers, in
C<$msgset> and C<fetch> responses.  This method is valid only when the
session is in the selected state.

=cut

sub uid_fetch {
  my $self = shift;
  my $msgset = shift;
  my @args;
  if (scalar(@_) == 1) {
    push @args, ATOM, shift;
  } else {
    push @args, PARENS, [@_];
  }
  $self->imap_command('uid fetch', ATOM, $msgset, @args);
}

=head2 uid_search [Charset => $charset,] @searchkeys

A variant of C<search> that uses UIDs, instead of message numbers, in
C<$msgset> and C<search> responses.  This method is valid only when
the session is in the selected state.

=cut

sub uid_search {
  my $self = shift;
  my @args;
  if ($_[0] =~ /^charset$/i) {
    shift;
    my $charset = shift;
    push @args, ATOM, 'charset', ASTRING, $charset;
  }
  push @args, map { (ATOM, $_) } @_;
  $self->imap_command('uid search', @args);
}

=head2 uid_store $msgset, $itemname, @storeattrflags

A variant of C<store> that uses UIDs, instead of message numbers, in
C<$msgset> and C<fetch> responses.  This method is valid only when the
session is in the selected state.

=cut

sub uid_store {
  my $self = shift;
  my $msgset = shift;
  my $itemname = shift;
  for my $flag (@_) {
    unless ($self->_valid_flag($flag)) {
      carp "$flag is not a system flag";
      return undef;
    }
  }
  $self->imap_command('uid store',
		      ATOM, $msgset, ATOM, $itemname, PARENS, [@_]);
}
###############################################################################

=head1 CONVENIENCE ROUTINES

In addition to the core protocol methods, C<Net::IMAP> provides
several methods for accessing various pieces of information.

=head2 is_preauth

Returns a boolean valud indicating whether the IMAP session is
preauthenticated.

=cut

sub is_preauth { $_[0]->{PreAuth} }

=head2 banner

Returns the banner string issued by the server at connect time.

=cut

sub banner { $_[0]->{Banner} }

=head2 capabilities

Returns the list of capabilities supported by the server, minus the
authentication capabilities.  The list is not guaranteed to be in any
specific order.

=cut

sub capabilities { keys %{$_[0]->{Capabilities}} }

=head2 has_capability $capname

Returns a boolean value indicating whether the server supports the
specified capability.

=cut

sub has_capability { defined($_[0]->{Capabilities}{uc($_[1])}) }

=head2 authtypes

Returns a list of authentication types supported by the server.

=cut

sub authtypes { keys %{$_[0]->{AuthTypes}} }

=head2 has_authtype $authname

Returns a boolean value indicating whether the server supports the
specified authentication type.

=cut

sub has_authtype { defined($_[0]->{AuthTypes}{uc($_[1])}) }

=head2 qty_messages

Returns the quantity of messages in the currently selected folder.

=cut

sub qty_messages { $_[0]->{MailboxStatus}{'exists'} }

=head2 qty_recent

Returns the quantity of recent messages in the currently selected folder.

=cut

sub qty_recent { $_[0]->{MailboxStatus}{'recent'} }

=head2 first_unseen

Returns the message number of the first unseen messages in the
currently selected folder.

=cut

sub first_unseen { $_[0]->{MailboxStatus}{'unseen'} }

=head2 uidvalidity

Returns the C<uidvalidity> value for the currently selected folder.
This is useful for IMAP clients that cache data in persistent storage.
Cache data for a mailbox should only be considered valid if the
C<uidvalidity> is the same for both cached data and the remote
mailbox.  See Section 2.3.1.1 of RFC2060 for further details.

=cut

sub uidvalidity { $_[0]->{MailboxStatus}{'uidvalidity'} }

=head2 uidnext

Returns the C<uidnext> value for the currently selected folder.

=cut

sub uidnext { $_[0]->{MailboxStatus}{'uidnext'} }

=head2 permanentflags

Returns the list of permanent flags the server has identified for the
currently open mailbox.

If a C<\*> flag is present, the server allows new persistent keywords
to be created.

=cut

sub permanentflags { keys %{$_[0]->{MailboxStatus}{'permanentflags'}} }

=head2 is_permanentflag $flag

Returns a boolean value indicating whether the server considers
C<$flag> to be a permanent flag.

=cut

sub is_permanentflag {
  defined($_[0]->{MailboxStatus}{'permanentflags'}{lc($_[1])});
}

=head2 flags

Returns a list of the flags associated with the mailbox.

=cut

sub flags { keys %{$_[0]->{MailboxStatus}{'flags'}} }

=head2 has_flag $flag

Returns a boolean value indicating whether the given $flag is defined
for the mailbox.

=cut

sub has_flag { defined($_[0]->{MailboxStatus}{'flags'}{lc($_[1])}) }

=head2 mailbox

Returns the name of the currently open mailbox.  Returns C<undef> if
no mailbox is currently open.

=cut

sub mailbox { $_[0]->{Mailbox} }

=head2 is_readonly

Returns a boolean value indicating whether the currently open mailbox
is read-only.

=cut

sub is_readonly { $_[0]->{ReadOnly} }

#------------------------------------------------------------------------------

sub _encode_mailbox {
  my $str = $_[0];
  $str =~ s/&/&-/g;
  return $str;
}

sub _decode_mailbox {
  my $str = $_[0];
  $str =~ s/&-/&/g;
  return $str;
}

###############################################################################

=head1 NAMESPACE EXTENSION

The following methods are available if the server advertises support
for RFC2342 (IMAP4 Namespace).  Refer to that RFC for additional
information.

=head2 namespace

Sends a C<namespace> command to the server, if the server advertises
support for the extension extension.

=cut

sub namespace {
  my $self = shift;
  return undef unless $self->has_capability('NAMESPACE');
  $self->imap_command('namespace');
}

###############################################################################

=head1 ACCESS CONTROL EXTENSION

The following methods are available if the server advertises support
for RFC2086 (IMAP4 ACL Extension).  Refer to that RFC for additional
information.

=head2 setacl $mailbox, $identifier, $modrights

Sets the access control list for C<$identifier> on C<$mailbox>
according to the rights contained in C<$modrights>.

The C<$identifier> typically identifies an account name, but can also
specify abstract entities, such as groups.

The format for C<$modrights> is documented in RFC2086.

=cut

sub setacl {
  my $self = shift;
  return undef unless $self->has_capability('ACL');
  $self->imap_command('setacl',
		      ASTRING, _encode_mailbox($_[0]),
		      ASTRING, $_[1],
		      ASTRING, $_[2]);
}

=head2 getacl $mailbox

Retrieves the access control list for C<$mailbox>.

=cut

sub getacl {
  my $self = shift;
  return undef unless $self->has_capability('ACL');
  $self->imap_command('getacl', ASTRING, _encode_mailbox($_[0]));
}

=head2 deleteacl $mailbox, $identifier

Deletes all access control list entries for C<$identifier> from
C<$mailbox>.

=cut

sub deleteacl {
  my $self = shift;
  return undef unless $self->has_capability('ACL');
  $self->imap_command('deleteacl',
		      ASTRING, _encode_mailbox($_[0]), ASTRING, $_[1]);
}

=head2 listrights $mailbox, $identifier

List the rights available to C<$identifier> for C<$mailbox>.

=cut

sub listrights {
  my $self = shift;
  return undef unless $self->has_capability('ACL');
  $self->imap_command('listrights',
		      ASTRING, _encode_mailbox($_[0]), ASTRING, $_[1]);
}

=head2 myrights $mailbox

List the rights the current user has for C<$mailbox>.

=cut

sub myrights {
  my $self = shift;
  return undef unless $self->has_capability('ACL');
  $self->imap_command('myrights', ASTRING, _encode_mailbox($_[0]));
}

###############################################################################

=head1 QUOTA EXTENSION

The following methods are available if the server advertises support
for RFC2087 (IMAP4 Quota Extension).  Refer to that RFC for additional
information.

=head2 getquota $quotaroot

Lists the resource usage and limits for C<$quotaroot>.

=cut

sub getquota {
  my $self = shift;
  return undef unless $self->has_capability('QUOTA');
  $self->imap_command('getquota', ASTRING, $_[0]);
}

=head2 setquota $quotaroot, @setquotalist

Sets the resource limits for C<$quotaroot> to C<@setquotalist>.

Valid values for C<@setquotalist> are server-dependant.

=cut

sub setquota {
  my $self = shift;
  my $quotaroot = shift;
  return undef unless $self->has_capability('QUOTA');
  $self->imap_command('setquota', ASTRING, $quotaroot, PARENS, [@_]);
}

=head2 getquotaroot $mailbox

Lists the quota roots for C<$mailbox>.

=cut

sub getquotaroot {
  return undef unless $_[0]->has_capability('QUOTA');
  $_[0]->imap_command('getquotaroot', ASTRING, _encode_mailbox($_[1]));
}

###############################################################################

=head1 UIDPLUS EXTENSION

The following method is available if the server advertises support for
RFC2359 (IMAP4 UIDPLUS Extension).  Refer to that RFC for additional
information.

=head2 uid_expunge $msgset

A variant of C<expunge> that allows the operation to be narrowed to
the messages with UIDs specified in C<$msgset>.

The C<$msgset> parameter is described in the section describing C<fetch>.

=cut

sub uid_expunge {
  return undef unless $_[0]->has_capability('UIDPLUS');
  $_[0]->imap_command('uid expunge', ATOM, $_[1]);
}

###############################################################################

sub imap_command {
  my $self = shift;
  if (!defined($cmd_callbacks{$_[0]})) {
    carp("unknown imap command: $_[0]");
    return undef;
  }
  unless ($cmd_callbacks{$_[0]}->[1] & $self->{State}) {
    carp("invalid state for issuing $_[0] command");
    return undef
  }
  $self->command($self->imap_cmd_callback($_[0]), @_);
}

###############################################################################

=head1 CALLBACKS

Many of the command methods result in the server sending back response
data.  C<Net::IMAP> processes each response by parsing the data,
packages it in an appropriate object, and optionally calls a
programmer-defined callback for the response.  This callback mechanism
is how programmers get access to the data retrieved from the server.

=head2 set_untagged_callback $item, $coderef

Assigns a programmer-defined code reference to the associated untagged
response.  When an untagged response matching C<$item> is received,
C<$coderef> is called, with the IMAP object and the associated
response object passed as parameters.

The default callback for the C<ok>, C<bye>, C<bad>, and C<no> untagged
responses includes code to output the text from C<alert> responses to
stderr, using C<carp>.  If you set your own callback for these
responses, be sure to code handle C<alert> codes.  Per Section 7.1 of
RFC2060, clients are required to clearly display C<alert> messages to
users.

=cut

sub set_untagged_callback {
  my $self = shift;
  my $item = shift;
  my $funcref = shift;

  return undef unless defined($untagged_callbacks{$item});
  $untagged_callbacks{$item}->[0] = $funcref;
}

#------------------------------------------------------------------------------

sub imap_cmd_callback {
  my $self = shift;
  my $cmd = shift;
  return sub {
    my $resp = shift;
    return unless (defined($cmd_callbacks{$cmd})
		   && defined($cmd_callbacks{$cmd}->[0]));
    my $func = $cmd_callbacks{$cmd}->[0];
    return $self->$func($resp);
  }
}

sub imap_response_callback {
  my $self = shift;
  # my $seq = $self->next_sequence;
  return sub {
    my $response = shift;
    my ($tag, $rest) = split(/\s/, $response, 2);
    if ($tag eq '*') {
      return $self->_imap_process_untagged_response($rest);
    } elsif ($tag =~ /^\d+$/) {
      return $self->_imap_process_tagged_response($tag, $rest);
    } else {
      croak("gack! server returned bogus tag: [$tag]");
    }
  }
}

sub _imap_process_untagged_response {
  my $self = shift;
  my $str = shift;
  my @args;
  my $num;

  my ($cmd, $rest) = split(/\s/, $str, 2);
  if ($cmd =~ /^\d+$/) {
    push @args, $cmd;
    ($cmd, $rest) = split(/\s/, $rest, 2);
  }
  push @args, $rest if defined($rest);
  $cmd = lc($cmd);
  if (defined($untagged_callbacks{$cmd})) {
    my $class = "Net::IMAP::" . ucfirst(lc($cmd));
    my $ret = $class->new($self, @args);

    # trigger a user callback, maybe - user callback is passed $self
    # and the object created by the internal callback

    if (defined($ret)) {
      if (defined($untagged_callbacks{$cmd}->[0])) {
	&{$untagged_callbacks{$cmd}->[0]}($self, $ret);
      }
      $self->debug_print(0, "untagged resp callback returned $ret")
	if $self->debug;
    } else {
      carp("untagged resp callback returned undef");
    }
    return undef;
  } else {
    carp("received unknown response from server: [$cmd]\n");
  }
}

sub _imap_process_tagged_response {
  my $self = shift;
  my $tag = shift;
  my $str = shift;

  my $resp = Net::IMAP::Response->new;

  my ($cond, $text) = split(/\s/, $str, 2);
  my $resp_code = undef;
  if (substr($text, 0, 1) eq '[') {
    ($resp_code, $text) = _extract_resp_code($text);
  }
  $resp->{Sequence} = $tag;
  $resp->{Status} = lc($cond);
  $resp->{StatusCode} = $resp_code;
  $resp->{Text} = $text;

  if ($self->{Disconnect}) {
    $self->close_connection or carp "error closing connection: $!";
  }
  return $resp;
}
###############################################################################
sub _select_cmd_callback {
  my $self = shift;
  my $resp = shift;

  if ($resp->status eq 'ok') {
    $self->{State} = IMAP_STATE_SELECT;
    my $status = $resp->status_code;
    $self->{ReadOnly} = (defined($status) && ($status->[0] eq 'read-only'));
  } else {
    $self->{State} = IMAP_STATE_AUTH;
    $self->{Mailbox} = '';
  }
}

sub _login_cmd_callback {
  $_[0]->{State} = IMAP_STATE_AUTH if ($_[1]->status eq 'ok');
}

sub _close_cmd_callback {
  if ($_[1]->status eq 'ok') {
    $_[0]->_init_mailbox;
    $_[0]->{State} = IMAP_STATE_AUTH;
  }
}
#------------------------------------------------------------------------------

sub _default_aux_callback {
  my $self = shift;
  my $resp = shift;

  my $code = $resp->code;
  if (defined($code) && ($code->[0] eq 'alert')) {
    carp "Alert: ", $resp->text, "\n";
  }
}

###############################################################################
sub _valid_flag { ((substr($_[1], 0, 1) ne "\\")
		   || defined($_system_flags{lc($_[1])})) }
###############################################################################
sub _extract_resp_code {
  my $line = shift;
  $line =~ m{
	     \[
	     ([^\]]+)		# response code
	     \]
	     (?:
	      \s
	      (.*)		# remainder of response line
	     )?
	     $
	    }x;
  my $resp_code = $1;
  my $rest = $2;
  my $resp_code_list = Net::xAP->parse_fields($resp_code);
  $resp_code_list->[0] = lc($resp_code_list->[0]);
  return($resp_code_list, $rest);
}
###############################################################################
# use Data::Dumper;
# sub _dump_internals { print STDERR "----\n", Dumper($_[0]), "----\n" }
###############################################################################

=head1 RESPONSE OBJECTS

As mention in the previous section, responses are parsed and packaged
into response objects, which are then passed to callbacks.  Each type
of response has a corresponding object class.  This section describes
the various response objects provided.

All of the class names itemized below are prefixed with C<Net::IMAP>.

As a general rule, IMAP C<nil> items are set to C<undef> in the parsed
data, and IMAP parenthetical lists are converted to list references
(of one form or another).  In addition, atoms, quoted strings, and
literals are presented as Perl strings.

The condition responses (C<ok>, C<no>, C<bad>, C<bye>, and C<preauth>)
can include a response code.  Refer to Section 7.1 in RFC2060 for a
description of each of the standard response codes.

=head1 Response

This is the object class for completion responses.

=head2 is_tagged

Returns a boolean value indicating whether the response is tagged.  In
the case of tagged completion responses, this value is always C<1>.

=cut

package Net::IMAP::Response;
use vars qw(@ISA);
@ISA = qw(Net::xAP::Response);

sub is_tagged { 1 }

=head2 has_trycreate

Returns a boolean value indicating whether the C<TRYCREATE> response
code is present in the response.  This can be used after a failed
C<append> or C<copy> command to determine whether the server thinks
the operation would succeed if a C<create> was issued for the
associated mailbox.

=cut

sub has_trycreate {
  my $status_code = $_[0]->status_code;
  return (defined($status_code) && (lc($status_code->[0]) eq 'trycreate'));
}

###############################################################################

=head1 UntaggedResponse

This class is common to all untagged server responses.

=head2 tag

Returns a string containing the tag associated with the response.  In
the case of untagged responses, this is always C<*>.

=head2 is_tagged

Returns a boolean value indicating whether the response is tagged.
Obviously, in the case of untagged responses, this value is always
C<0>.

=head2 parent

Returns a reference to the parent IMAP object.

=cut

package Net::IMAP::UntaggedResponse;

sub tag { '*' }
sub is_tagged { 0 }
sub parent { $_[0]->{Parent} }
#------------------------------------------------------------------------------
package Net::IMAP::Cond;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);
use Carp;

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  my $resp_code = undef;

  if (substr($str, 0, 1) eq '[') {
    ($resp_code, $str) = Net::IMAP::_extract_resp_code($str);
  }
  $self->{RespCode} = $resp_code;
  $self->{Text} = $str;

  carp "Alert: $str\n" if (defined($resp_code) && $resp_code->[0] eq 'alert');

  if (($self->name eq 'bye') && !$self->parent->{Disconnect}) {
    # a logout command wasn't issued, so it's probably the result of
    # an autologout timer expiring
    $self->parent->close_connection or carp "error closing connection: $!";
  }

  return $self;
}

sub code { $_[0]->{RespCode} }

sub name { undef }
#------------------------------------------------------------------------------

=head1 Ok

This is a container for untagged C<ok> responses from the server.

=head2 code

Returns a list reference containing response code elements in the
response.  Returns C<undef> if no response code is present.

=head2 name

Returns the name of the response.  In the case of C<Ok>, this returns
'ok'.  This method is provided as a convenience for end-programmers
wanting to write one common subroutine for one or more of the
responses C<Ok>, C<No>, C<Bad>, and C<Bye>.

=cut

package Net::IMAP::Ok;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::Cond);
sub name { 'ok' };
#------------------------------------------------------------------------------

=head1 No

This is a container for untagged C<no> responses from the server.

=cut

package Net::IMAP::No;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::Cond);
sub name { 'no' };
#------------------------------------------------------------------------------

=head1 Bad

This is a container for untagged C<bad> responses from the server.

=cut

package Net::IMAP::Bad;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::Cond);
sub name { 'bad' };
#------------------------------------------------------------------------------

=head1 Bye

This is a container for untagged C<bye> responses from the server.

=cut

package Net::IMAP::Bye;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::Cond);
sub name { 'bye' };
###############################################################################

=head1 Expunge

This is a container for C<expunge> responses from the server.

The information returned by C<qty_messages> is automatically updated
when C<expunge> responses are received.

=head2 msgnum

Returns the message number specified in the C<expunge> response.

=cut

package Net::IMAP::Expunge;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'expunge' }

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  $self->{Msgnum} = $str;

  return $self;
}

sub msgnum { $_->{Msgnum} }

###############################################################################

=head1 Capability

This is a container for C<capability> responses.

=head2 capabilities

Returns the list of capabilities supported by the server, minus the
authentication capabilities.  The list is not guaranteed to be in any
specific order.

=head2 has_capability $capname

Returns a boolean value indicating whether the server supports the
specified capability.

=head2 authtypes

Returns a list of authentication types supported by the server.

=head2 has_authtype $authname

Returns a boolean value indicating whether the server supports the
specified authentication type.

=cut

package Net::IMAP::Capability;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'capability' }

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  undef $self->{Parent}{Capabilities}; # needs to be repopulated each time
  undef $self->{Parent}{AuthTypes}; # needs to be repopulated each time

  for my $cap (split(/\s/, $str)) {
    $cap = uc($cap);
    $self->{Parent}{Capabilities}{$cap}++;
    $self->{Parent}{AuthTypes}{$1}++ if $cap =~ /^AUTH=(.*)$/;
    $self->{Capabilities}{$cap}++;
    $self->{AuthTypes}{$1}++ if $cap =~ /^AUTH=(.*)$/;
  }

  # force the non-synchronous literals option off if the server
  # doesn't support it
  $self->{Parent}{Options}{NonSyncLits} = 0
    unless defined($self->{Parent}{Capabilities}{'LITERAL+'});

  return $self;
}

sub capabilities { keys %{$_[0]->{Capabilities}} }

sub has_capability { defined($_[0]->{Capabilities}{uc($_[1])}) }

sub authtypes { keys %{$_[0]->{AuthTypes}} }

sub has_authtype { defined($_[0]->{AuthTypes}{uc($_[1])}) }

###############################################################################

=head1 List

This is a container for C<list> responses.

=head2 mailbox

Returns the name of the mailbox contained in the object.

=head2 delimiter

Returns the hierarchy delimiter associated with the mailbox.

=head2 flags

Returns a list of the flags associated with the mailbox.

=head2 has_flag $flag

Returns a boolean value indicating whether the given $flag is defined
for the mailbox.

=cut

package Net::IMAP::List;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'list' }

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  my $fields = Net::xAP->parse_fields($str);
  for my $flag (@{$fields->[0]}) {
    $self->{Flags}{lc($flag)}++;
  }
  $self->{Delim} = $fields->[1];
  $self->{Mailbox} = Net::IMAP::_decode_mailbox($fields->[2]);

  return $self;
}

sub mailbox { $_[0]->{Mailbox} }
sub delimiter { $_[0]->{Delim} }
sub flags { keys %{$_[0]->{Flags}} }
sub has_flag { defined($_[0]->{Flags}{lc($_[1])}) }

#------------------------------------------------------------------------------

=head1 List

This is a container for C<lsub> responses.  It provides the same
interface as the C<Net::IMAP::List> class.

=cut

package Net::IMAP::Lsub;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::List);

sub name { 'lsub' }

###############################################################################

=head1 Fetch

This is a container for C<fetch> responses.

Responses for partial fetches bear special mention.  While both the
starting byte and quantity of bytes are specified when doing partial
fetches with the C<fetch> command, the corresponding response will
only show the starting byte.  In other words, the command
C<$imap-E<gt>fetch(1, 'body[]E<lt>0.1024E<gt>'> will, if successful,
result in a fetch response item of C<body[]E<lt>0E<gt>> containing a
1024 octet value.  To match a given response for a partial fetch, you
might need to use C<length> to match it up with the corresponding item
specified in the C<fetch> command.

=head2 msgnum

Returns the message number identified in the response.

=head2 items

Returns the list of data item names contained in the response.  The
list is not guaranteed to be in any specific order.

=head2 item $item

Returns the data associated with the specified data item.

The following list enumerates the data types associated with each
fetch item:

=over 14

=item envelope

Net::IMAP::Envelope

=item bodystructure

Net::IMAP::BodyStructure

=item body

Net::IMAP::BodyStructure

=item flags

Net::IMAP::Flags

=item UID

Integer

=item rfc822.size

Integer

=item I<default>

String

=back

=cut

package Net::IMAP::Fetch;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'fetch' }

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $msgnum = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  $self->{Msgnum} = $msgnum;

  my %hash = @{Net::xAP->parse_fields($str)->[0]};
  for my $key (keys %hash) {
    my $lckey = lc($key);
    print "$lckey $hash{$key}\n";
    if ($lckey eq 'envelope') {
      $self->{Items}{$lckey} = Net::IMAP::Envelope->new($hash{$key});
    } elsif (($lckey eq 'bodystructure') || ($lckey eq 'body')) {
      $self->{Items}{$lckey} = Net::IMAP::BodyStructure->new($hash{$key});
    } elsif ($lckey eq 'flags') {
      $self->{Items}{$lckey} = Net::IMAP::Flags->new($parent);
      for my $flag (@{$hash{$key}}) {
	$self->{Items}{$lckey}{Flags}{lc($flag)}++;
      }
    } else {
      if ($self->{Parent}{Options}{EOL} eq 'lf') {
	if ((substr($lckey, 0, 5) eq 'body[')
	    || ($lckey eq 'rfc822')
	    || ($lckey eq 'rfc822.header')
	    || ($lckey eq 'rfc822.text')) {
	  $hash{$key} =~ s/\r\n/\n/mg;
	}
      }
      $self->{Items}{$lckey} = $hash{$key};
    }
  }

  return $self;
}

sub msgnum { $_[0]->{Msgnum} }
sub items { keys %{$_[0]->{Items}} }
sub item { $_[0]->{Items}{lc($_[1])} }

###############################################################################

=head1 Status

This is a container for C<status> responses.

=head2 mailbox

Returns a string containing the mailbox the status information is
associated with.

=head2 items

Returns the list of status items contains in the status response.

=head2 item $item

Returns the value of the C<$item> status item.

=cut

package Net::IMAP::Status;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'status' }

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  my $fields = Net::xAP->parse_fields($str);
  $self->{Mailbox} = Net::IMAP::_decode_mailbox($fields->[0]);
  my %hash = @{$fields->[1]};
  for my $key (keys %hash) {
    $self->{Items}{lc($key)} = $hash{$key};
  }

  return $self;
}

sub mailbox { $_[0]->{Mailbox} }
sub items { keys %{$_[0]->{Items}} }
sub item { $_[0]->{Items}{lc($_[1])} }

###############################################################################

=head1 Search

This is a container for C<search> responses.

=head2 msgnums

Returns the list of message numbers contained in the response.

=cut

package Net::IMAP::Search;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'search' }

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  for my $item (split(/\s/, $str)) {
    $self->{Msgnums}{$item}++;
  }

  return $self;
}

sub msgnums { keys %{$_[0]->{Msgnums}} }

###############################################################################

=head1 Flags

This is a container for C<flags> responses.

=head2 flags

Returns the list of flags contained in the response.

=head2 has_flag $flag

Returns a boolean value indicating whether the specified flag is
contained in the response.

As a convenience, the information from the C<flags> response is also
stored in the parent C<Net::IMAP> object, and is available via
C<Net::IMAP> versions of the C<flags> and C<has_flags> methods.

=cut

package Net::IMAP::Flags;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'flags' }

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  if (defined($str)) {
    for my $flag (@{Net::xAP->parse_fields($str)->[0]}) {
      $self->{Flags}{lc($flag)}++;
      $self->{Parent}{MailboxStatus}{'flags'}{lc($flag)}++;
    }
  }

  return $self;
}

sub flags { keys %{$_[0]->{Flags}} }
sub has_flag { defined($_[0]->{Flags}{lc($_[1])}) }

###############################################################################

=head1 Exists

This is a container for C<exists> responses.

=head2 exists

Returns the quantity of messages in the currently selected mailbox.

This is information is also available in the C<qty_messages> method in
the C<Net::IMAP> class.

=cut

package Net::IMAP::Exists;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'exists' }

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  $self->{Parent}{MailboxStatus}{'exists'} = $str;
  $self->{Value} = $str;

  return $self;
}

sub exists { $_[0]->{Value} }

###############################################################################

=head1 Recent

This is a container for C<recent> responses.

=head2 recent

Returns the number of messages with the C<\recent> flag set.

This information is also available in the C<qty_recent> method in the
C<Net::IMAP> class.

=cut

package Net::IMAP::Recent;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'recent' }

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  $self->{Parent}{MailboxStatus}{'recent'} = $str;
  $self->{Value} = $str;

  return $self;
}

sub recent { $_[0]->{Value} }

###############################################################################

=head1 Namespace

This is a container for C<namespace> responses.

=head2 personal [$namespace]

With no argument specified, returns a list of personal namespaces.  If
C<$namespace> is specified, returns the delimiter character for the
specific personal namespace.

=head2 other_users [$namespace]

With no argument specified, returns a list of other users' namespaces.
If C<$namespace> is specified, returns the delimiter character for the
specific other users' namespace.

=head2 shared [$namespace]

With no argument specified, returns a list of shared namespaces.  If
C<$namespace> is specified, returns the delimiter character for the
specific shared namespace.

=cut

package Net::IMAP::Namespace;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'namespace' }

my @namespace_types = qw(personal other_users shared);

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  my $fields = Net::xAP->parse_fields($str);
  for my $n (0 .. 2) {
    my $field = $fields->[$n];
    for my $item (@{$field}) {
      $item->[1] = '' if (lc($item->[1]) eq 'nil');
      $self->{Namespaces}{$namespace_types[$n]}{$item->[0]} = $item->[1];
    }
  }

  return $self;
}

sub personal {
  return $_[0]->{Namespaces}{'personal'}{lc($_[1])} if (defined($_[1]));
  keys %{$_[0]->{Namespaces}{'personal'}};
}

sub other_users {
  return $_[0]->{Namespaces}{'other_users'}{lc($_[1])} if (defined($_[1]));
  keys %{$_[0]->{Namespaces}{'other_users'}};
}

sub shared {
  return $_[0]->{Namespaces}{'shared'}{lc($_[1])} if (defined($_[1]));
  keys %{$_[0]->{Namespaces}{'shared'}};
}

###############################################################################

=head1 ACL

This is a container for C<acl> responses>

=head2 mailbox

Returns the name of the mailbox associated with the given ACL data.

=head2 identifiers

Returns a list of identifiers contained in the ACL data.

=head2 identifier $identifier

=cut

package Net::IMAP::Acl;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'acl' }

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  my @fields = @{Net::xAP->parse_fields($str)};
  $self->{Mailbox} = shift(@fields);
  my %hash = @fields;
  for my $key (keys %hash) {
    $self->{Identifiers}{lc{$key}} = $hash{$key};
  }

  return $self;
}

sub mailbox { $_[0]->{Mailbox} }
sub identifiers { keys %{$_[0]->{Identifiers}} }
sub identifier { $_[0]->{Identifiers}{lc($_[1])} }

###############################################################################

=head1 Listrights

This is a container for C<listrights> responses.

=head2 mailbox

Returns the name of the mailbox associated with the given rights.

=head2 identifier

Returns a string containing the identifier associated with the rights.

=head2 rights

Returns a string containing the rights contained in the response.

=cut

package Net::IMAP::Listrights;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'listrights' }

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  my @fields = @{Net::xAP->parse_fields($str)};
  $self->{Mailbox} = shift(@fields);
  $self->{Identifier} = shift(@fields);
  $self->{Rights} = [@fields];

  return $self;
}

sub mailbox { $_[0]->{Mailbox} }
sub identifier { $_[0]->{Identifier} }
sub rights { (wantarray) ? @{$_[0]->{Rights}} : $_[0]->{Rights} }

###############################################################################

=head1 Myrights

This is a container for C<myrights> responses>

=head2 mailbox

Returns the name of the mailbox associated with the given rights.

=head2 rights

Returns a string containing the rights contained in the response.

=cut

package Net::IMAP::Myrights;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'myrights' }

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  my $fields = Net::xAP->parse_fields($str);
  $self->{Mailbox} = $fields->[0];
  $self->{Rights} = $fields->[1];

  return $self;
}

sub mailbox { $_[0]->{Mailbox} }
sub rights { $_[0]->{Rights} }

###############################################################################

=head1 Quota

This is a container for C<quota> responses.

=head2 quotaroot

Returns a string containing the name of the quota root in the response.

=head2 quotas

Returns a list of the quotas contained in the response.

=head2 usage $quota

Returns the usage value associated with the given C<$quota>.  Returns
C<undef> is the given C<$quota> is not present in the response.

=head2 limit $quota

Returns the usage limit associated with the given C<$quota>.  Returns
C<undef> is the given C<$quota> is not present in the response.

=cut

package Net::IMAP::Quota;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'quota' }

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  my @fields = @{Net::xAP->parse_fields($str)};
  $self->{QuotaRoot} = shift(@fields);
  while (@fields) {
    my ($resource, $usage, $limit) = splice(@fields, 0, 3);
    $self->{Quota}{lc($resource)} = [$usage, $limit];
  }

  return $self;
}

sub quotaroot { $_[0]->{QuotaRoot} }
sub quotas { keys %{$_[0]->{Quotas}} }
sub usage { $_[0]->{Quotas}{lc($_[1])}->[0] }
sub limit { $_[0]->{Quotas}{lc($_[1])}->[1] }

###############################################################################

=head1 Quotaroot

This is a container for C<quotaroot> responses.

=head2 mailbox

Returns the name of the mailbox associated with the quotaroot data.

=head2 quotaroots

If called in an array context, returns the list of quotaroots
associated with the mailbox.  If called in a scalar context, returns a
list reference.

=cut

package Net::IMAP::Quotaroot;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::UntaggedResponse);

sub name { 'quotaroot' }

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $parent = shift;
  my $str = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parent} = $parent;

  my @fields = @{Net::xAP->parse_fields($str)};
  $self->{Mailbox} = shift(@fields);
  $self->{Quotaroots} = [@fields];

  return $self;
}

sub mailbox { $_[0]->{Mailbox} }
sub quotaroots { (wantarray) ? @{$_[0]->{Quotaroots}} : $_[0]->{Quotaroots} }

###############################################################################

=head1 MISC FETCH OBJECTS

A C<fetch> response can be relatively complicated.  This section
documents various classes and methods associated with the various
pieces of information available in C<fetch> responses.

=cut

package Net::IMAP::FetchData;

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $self = [];
  if (defined($_[0])) {
    push(@{$self},
	 map {
	   (lc($_) eq 'nil') ? undef : Net::xAP->dequote($_)
	 } @{$_[0]});
  }
  bless $self, $class;
}

###############################################################################

=head1 BodyStructure

This is a container for C<bodystructure> items in C<fetch> responses.

=head2 type

Returns a string containing the MIME type of the message.  This is the
left-hand portion of a MIME media type.  For example, the type of
C<text/plain> is C<text>.

=head2 subtype

Returns a string containing the MIME subtype of the message.  This is
the right-hand portion of a MIME media type.  For example, the subtype
of C<text/plain> is C<plain>.

=head2 parameters

Returns a reference to a hash containing the key/value attribute pairs
in the C<Content-Type> field.

If, for example, the C<Content-Type> field was:

  Content-Type: text/plain; charset=us-ascii

The hash would contain one entry the a key of C<charset>, and a value
of C<us-ascii>.  The key is always forced to be lowercase, but the
case of the value is retained from the server.

=head2 disposition

Returns the disposition type in the C<Content-Disposition> field.
Returns C<undef> if no such field exists.

=head2 disp_parameters

Returns a reference to a hash containing the key/value attributer
pairs in the C<Content-Disposition> field.  A reference to an empty
hash is returned if no such field exists, or if there are no
parameters in the field.

=head2 language

Returns a reference to a list of the language tags present in the
C<Content-Language> field.  Returns a reference to an empty hash if no
such field is present.

=cut

package Net::IMAP::BodyStructure;

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $data = shift;

  return Net::IMAP::Multipart->new($data) if (ref($data->[0]) eq 'ARRAY');
  return Net::IMAP::Bodypart->new($data);
}

sub subtype { $_[0]->{Subtype} }
sub parameters { $_[0]->{Parms} }
sub disposition { $_[0]->{Disp} }
sub disp_parameters { $_[0]->{DispParms} }
sub language { $_[0]->{Lang} }

sub _parse_parms {
  my $self = shift;
  my $data = shift;
  if (ref($data) eq 'ARRAY') {
    my @parms = @{$data};
    while (@parms) {
      my ($key, $value) = splice(@parms, 0, 2);
      $self->{Parms}{lc($key)} = $value;
    }
  }
}

sub _parse_disp {
  my $self = shift;
  my $data = shift;

  $self->{Disp} = lc($data);
  if (ref($data) eq 'ARRAY') {
    if (lc($data->[1]) ne 'nil') {
      my @parms = @{$data->[1]};
      while (@parms) {
	my ($key, $value) = splice(@parms, 0, 2);
	$self->{DispParms}{lc($key)} = $value;
      }
    }
  }
}

sub _parse_lang {
  my $self = shift;
  my $data = shift;

  $data = lc($data);
  if ($data ne 'nil') {
    if (ref($data) eq 'ARRAY') {
      $self->{Lang} = [map { lc($_) } @{$data}];
    } else {
      $self->{Lang} = [lc($data)];
    }
  }
}

#------------------------------------------------------------------------------

=head1 Multipart

This is a container for C<BodyStructure objects that are multipart entities.

=head2 parts

Returns a list reference of the body parts contained in the multipart
entity.

=cut

package Net::IMAP::Multipart;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::BodyStructure);

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $data = shift;

  my $self = {};

  bless $self, $class;

  $self->{Parts} = [];

  my $i = 0;
  for my $item (@{$data}) {
    last if (ref($item) ne 'ARRAY');
    if (ref($item->[0]) eq 'ARRAY') {
      push @{$self->{Parts}}, Net::IMAP::Multipart->new($item);
    } else {
      push @{$self->{Parts}}, Net::IMAP::Bodypart->new($item);
    }
    $i++;
  }

  $self->{Subtype} = lc(Net::xAP->dequote($data->[$i++]));

  $self->{Parms} = {};
  $self->{Disp} = undef;
  $self->{DispParms} = {};
  $self->{Lang} = undef;

  if (defined($data->[$i])) {
    $self->_parse_parms($data->[$i++]);
    if (defined($data->[$i])) {
      $self->_parse_disp($data->[$i++]);
      if (defined($data->[$i])) {
	$self->_parse_lang($data->[$i++]);
	if (defined($data->[$i])) {
	  carp("Note: bodystructure contains unknown extension fields\n");
	}
      }
    }
  }

  return $self;
}

sub type { 'multipart' }
sub parts { $_[0]->{Parts} }

#------------------------------------------------------------------------------

=head1 Bodypart

This is a container for singlepart entities in C<BodyStructure> and
C<Multipart> objects.

=head2 id

Return a string containing the contents of the C<Content-ID> field, if
one is present, otherwise returns undef.

=head2 description

Return a string containing the contents of the C<Content-Description>
field, if one is present, otherwise returns undef.

=head2 encoding

Returns a string containing the contents of the
C<Content-Transfer-Encoding> field.  Returns C<undef> if no such field
is in the entity.

=head2 size

Returns the number of octets in the entity.

=head2 lines

If the MIME content type is C<message/rfc822> or the major type is
C<text>, returns the number of lines in the entity, else returns C<undef>.

=head2 envelope

If the MIME content type is C<message/rfc822, returns a
C<Net::IMAP::Envelope> object, otherwise returns undef.

=head2 bodystructure

If the MIME content type is C<message/rfc822, returns a
C<Net::IMAP::BodyStructure> object, otherwise returns undef.

=head2 md5

Returns a string containing the contents of the C<Content-MD5> field.
Returns C<undef> if no such field is in the entity.

=cut

package Net::IMAP::Bodypart;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::BodyStructure);
use Carp;

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $data = shift;

  my $self = {};

  bless $self, $class;

  my $i = 0;

  $self->{Type} = lc(Net::xAP->dequote($data->[$i++]));
  $self->{Subtype} = lc(Net::xAP->dequote($data->[$i++]));
  $self->{Parms} = {};
  $self->_parse_parms($data->[$i++]);
  $self->{Id} = Net::xAP->dequote($data->[$i++]);
  $self->{Description} = Net::xAP->dequote($data->[$i++]);
  $self->{Encoding} = lc(Net::xAP->dequote($data->[$i++]));
  $self->{Size} = $data->[$i++];

  if (($self->{Type} eq 'message') && ($self->{Subtype} eq 'rfc822')) {
    $self->{Envelope} = Net::IMAP::Envelope->new($data->[$i++]);
    $self->{Bodystructure} = Net::IMAP::BodyStructure->new($data->[$i++]);
    $self->{Lines} = $data->[$i++];
  } elsif ($self->{Type} eq 'text') {
    $self->{Lines} = $data->[$i++];
  }

  $self->{Envelope} ||= undef;
  $self->{BodyStructure} ||= undef;
  $self->{Lines} ||= undef;

  if (defined($data->[$i])) {
    $self->{MD5} = Net::xAP->dequote($data->[$i++]);
    if (defined($data->[$i])) {
      $self->_parse_disp($data->[$i++]);
      if (defined($data->[$i])) {
	$self->_parse_lang($data->[$i++]);
	if (defined($data->[$i])) {
	  carp("Note: bodystructure contains unknown extension fields\n");
	}
      }
    }
  }

  $self->{MD5} ||= undef;
  $self->{Disp} ||= undef;
  $self->{DispParms} ||= {};
  $self->{Lang} ||= undef;

  return $self;
}

sub type { $_[0]->{Type} }
sub id { $_[0]->{Id} }
sub description { $_[0]->{Description} }
sub encoding { $_[0]->{Encoding} }
sub size { $_[0]->{Size} }
sub lines { $_[0]->{Lines} }	# message/rfc822 and text/*
sub envelope { $_[0]->{Envelope} } # message/rfc822
sub bodystructure { $_[0]->{Bodystructure} } # message/rfc822
sub md5 { $_[0]->{MD5} }

###############################################################################

=head1 Envelope

This is a container for envelope data in C<fetch> responses.

For those familiar with SMTP, this is not the same type envelope.
Rather, it is a composite structure containing key source,
destination, and reference information in the message.  When retrieved
from the server, it is populated into a C<Net::IMAP::Envelope> object.
The following methods are available.

=head2 date

Returns a string with the contents of the C<Date> field.

=head2 subject

Returns a string with the contents of the C<Subject> field.

=head2 from

Returns a list reference of C<Net::IMAP::Addr> objects with the
contents of the C<From> field.

=head2 sender

Returns a list reference of C<Net::IMAP::Addr> objects with the
contents of the C<Sender> field.  If no C<Sender> field is present in
the message, the server will default it to the contents of the C<From>
field.

=head2 reply_to

Returns a list reference of C<Net::IMAP::Addr> objects with the
contents of the C<Reply-To> field.  If no C<Reply-To> field is present
in the message, the server will default it to the contents of the
C<From> field.

=head2 to

Returns a list reference of C<Net::IMAP::Addr> objects with the
contents of the C<To>field.  Will return C<undef> if no C<To> field
exists in the message.

=head2 cc

Returns a list reference of C<Net::IMAP::Addr> objects with the
contents of the C<Cc> field.  Will return C<undef> if no C<Cc> field
exists in the message.

=head2 bcc

Returns a list reference of C<Net::IMAP::Addr> objects with the
contents of the C<Bcc> field.  Will return C<undef> if no C<Bcc> field
exists in the message.

=head2 in_reply_to

Returns a string with the contents of the C<In-Reply-To> field.
Returns C<undef> if no such field is present in the message.

=head2 message_id

Returns a string with the contents of the C<Date> field.  Returns
C<undef> if no such field is present in the message.

=cut

package Net::IMAP::Envelope;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::FetchData);

sub new {
  my $class = shift;
  my $type = ref($class) || $class;
  my $data = shift;

  my $self = Net::IMAP::FetchData->new
    or return undef;

  bless $self, $class;

  $self->[0] = Net::xAP->dequote($data->[0]);
  $self->[1] = Net::xAP->dequote($data->[1]);
  for my $i (2 .. 7) {
    if (lc($data->[$i]) eq 'nil') {
      $self->[$i] = undef;
      next;
    }
    push @{$self->[$i]}, map { Net::IMAP::Addr->new($_) } @{$data->[$i]};
  }
  $self->[8] = Net::xAP->dequote($data->[8]);
  $self->[9] = Net::xAP->dequote($data->[9]);

  return $self;
}

sub date { $_[0]->[0] }
sub subject { $_[0]->[1] }
sub from { $_[0]->[2] }
sub sender { $_[0]->[3] }
sub reply_to { $_[0]->[4] }
sub to { $_[0]->[5] }
sub cc { $_[0]->[6] }
sub bcc { $_[0]->[7] }
sub in_reply_to { $_[0]->[8] }
sub message_id { $_[0]->[9] }

#------------------------------------------------------------------------------

=head1 Addr

This is a container for address structures in C<Envelope> objects.

=head2 phrase

Returns a string containing the phrase portion of the address, or
C<undef> if no phrase is present.

=head2 route

Returns a string containing the route portion of the address, or
C<undef> if no route information is present.

=head2 localpart

Returns a string containing the localpart portion of the address, or
C<undef> if no localpart is present.

=head2 domain

Returns a string containing the domain portion of the address, or
C<undef> if no domain is present.

=head2 as_string

Returns a string representation of the contents of the object.

=cut

package Net::IMAP::Addr;
use vars qw(@ISA);
@ISA = qw(Net::IMAP::FetchData);

sub phrase { $_[0]->[0] }
sub route { $_[0]->[1] }
sub localpart { $_[0]->[2] }
sub domain { $_[0]->[3] }

sub as_string {
  my $self = shift;
  my $str;
  my $domain = $self->domain;
  my $localpart = $self->localpart;
  my $route = $self->route;
  my $phrase = $self->phrase;

  return undef if (!defined($domain)); # part of a group list
  return undef if (!defined($localpart));

  $str = "$localpart\@$domain";
  if (defined($route) || defined($phrase)) {
    $str = "$route:$str" if defined($route);
    $str = "<$str>";		# route-addrs and phrases need <>
    $str = "$phrase $str" if defined($phrase);
  }
  return $str;
}

###############################################################################

=head1 CAVEATS

Minimal testing has been done against the various IMAP server
implementations.  Refer to C<BUGS> for known bugs/malfeatures.

=head1 AUTHOR

Kevin Johnson E<lt>F<kjj@pobox.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1997-1999 Kevin Johnson <kjj@pobox.com>.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
