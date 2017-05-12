package Protocol::IMAP::Server;
{
  $Protocol::IMAP::Server::VERSION = '0.004';
}
use strict;
use warnings;
use parent qw{Protocol::IMAP};

=head1 NAME

Protocol::IMAP::Server - server support for the Internet Message Access Protocol.

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 package Example::IMAP::Server;
 use parent qw{Protocol::IMAP::Server};

 package main;
 Example::IMAP::Server->new;

=head1 DESCRIPTION


=head1 IMPLEMENTING SUBCLASSES

The L<Protocol::IMAP> classes only provides the framework for handling IMAP data. Typically you would need to subclass these to get a usable IMAP implementation.

The following methods are required:

=over 4

=item * write - called at various points to send data back across to the other side of the IMAP connection

=back

and just about anything relating to the storage and handling of messages.

=cut

=head2 new

=cut

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	return $self;
}

sub on_connect {
	my $self = shift;
	$self->send_untagged("OK", "Net::Async::IMAP::Server ready.");
	$self->state(Protocol::IMAP::ConnectionEstablished);
}

sub send_untagged {
	my ($self, $cmd, @data) = @_;
	$self->debug("Send untagged command $cmd");
	$self->write("* $cmd" . (@data ? join(' ', '', @data) : '') . "\n");
}

sub send_tagged {
	my ($self, $id, $status, @data) = @_;
	$self->debug("Send tagged command $status for $id");
	$self->write("$id $status" . (@data ? join(' ', '', @data) : '') . "\n");
}

=head2 read_command

Read a command from a single line input from the client.

If this is a supported command, calls the relevant request_XXX method with the following data as a hash:

=over 4

=item * tag - IMAP tag information for this command, used for the final response from the server

=item * command - actual command requested

=item * param - any additional parameters passed after the command

=back

=cut

sub read_command {
	my $self = shift;
	my $data = shift;
	my ($id, $cmd, $param) = split / /, $data, 3;
	my $method = "request_" . lc $cmd;
	if($self->can($method)) {
		return $self->$method(
			id	=> $id,
			command => $cmd,
			param	=> $param
		);
	} else {
		return $self->send_tagged($id, 'BAD', 'wtf dude');
	}
}

=head2 request_capability

Request a list of all capabilities provided by the server.

These will be returned in a single untagged response, followed by the usual status response.

Note that the capabilities may vary depending on the state of the connection - for example, before STARTTLS negotiation
all login types may be disabled via LOGINDISABLED capability.

=cut

sub request_capability {
	my $self = shift;
	my %args = @_;
	if(length $args{param}) {
		$self->send_tagged($args{id}, 'BAD', 'Extra parameters detected');
	} else {
		$self->send_untagged('CAPABILITY', @{$self->{capabilities}});
		$self->send_tagged($args{id}, 'OK', 'Capability completed');
	}
}

=head2 request_starttls

Instructs the client to begin STARTTLS negotiation.

All implementations should provide this.

=cut

sub request_starttls {
	my $self = shift;
	my %args = @_;
	if(!$self->can('on_starttls')) {
		$self->send_tagged($args{id}, 'BAD', 'Unknown command');
	} elsif(length $args{param}) {
		$self->send_tagged($args{id}, 'BAD', 'Extra parameters detected');
	} else {
		$self->send_tagged($args{id}, 'OK', 'Begin TLS negotiation now.');
		$self->on_starttls;
	}
}

=head2 request_authenticate

Requests SASL authentication. Didn't need it, haven't written it yet.

=cut

sub request_authenticate {
	my $self = shift;
	my %args = @_;
	if(0) {
		my ($user, $pass);
		my $sasl = Authen::SASL->new(
			mechanism => $args{param},
			callback => {
	# TODO Convert these to plain values or sapped entries
				pass => sub { $pass },
				user => sub { $user },
				authname => sub { warn @_; }
			}
		);
		my $s = $sasl->server_new(
			'imap',
			$self->server_name,
			0,
		);
	}
	$self->send_tagged($args{id}, 'NO', 'Not yet supported.');
}

=head2 is_authenticated

Returns true if we are authenticated, false if not.

=cut

sub is_authenticated {
	my $self = shift;
	return $self->state == Protocol::IMAP::Authenticated || $self->state == Protocol::IMAP::Selected;
}

=head2 request_login

Process a login request - this will be delegated to the subclass L<validate_user> method.

=cut

sub request_login {
	my $self = shift;
	my %args = @_;
	$self->debug("Param was [" . $args{param} . "]");
	my ($user, $pass) = split ' ', $args{param}, 2;
	if($self->validate_user(user => $user, pass => $pass)) {
		$self->state(Protocol::IMAP::Authenticated);
		$self->send_tagged($args{id}, 'OK', 'Logged in.');
	} else {
		$self->send_tagged($args{id}, 'NO', 'Invalid user or password.');
	}
}

=head2 request_logout

Process a logout request.

=cut

sub request_logout {
	my $self = shift;
	my %args = @_;
	if(length $args{param}) {
		$self->send_tagged($args{id}, 'BAD', 'Extra parameters detected');
	} else {
		$self->send_untagged('BYE', 'IMAP4rev1 server logging out');
		$self->state(Protocol::IMAP::NotAuthenticated);
		$self->send_tagged($args{id}, 'OK', 'Logout completed.');
	}
}

=head2 request_noop

Handle a NOOP, which leaves state unchanged other than resetting any timers (as handled by the L<read_command> method).

=cut

sub request_noop {
	my $self = shift;
	my %args = @_;
	if(length $args{param}) {
		$self->send_tagged($args{id}, 'BAD', 'Extra parameters detected');
	} else {
		$self->send_tagged($args{id}, 'OK', 'NOOP completed');
	}
}

=head2 request_select

Select a mailbox.

=cut

sub request_select {
	my $self = shift;
	my %args = @_;
	unless($self->is_authenticated) {
		return $self->send_tagged($args{id}, 'NO', 'Not authorized.');
	}
	if(my $mailbox = $self->select_mailbox(mailbox => $args{param}, readonly => 1)) {
		$self->send_mailbox_info($mailbox);
		$self->send_tagged($args{id}, 'OK', 'Mailbox selected.');
	} else {
		$self->send_tagged($args{id}, 'NO', 'Mailbox not found.');
	}
}

=head2 C<send_mailbox_info>

Return untagged information about the selected mailbox.

=cut

sub send_mailbox_info {
	my ($self, $mailbox) = @_;
	$self->send_untagged(exists $mailbox->{'exists'} ? $mailbox->{'exists'} : 0, 'EXISTS');
	$self->send_untagged(exists $mailbox->{'recent'} ? $mailbox->{'recent'} : 0, 'RECENT');
	$self->send_untagged('OK', '[UNSEEN ' . ($mailbox->{'first_unseen'} || 0) . ']', 'First unseen message ID');
	$self->send_untagged('OK', '[UIDVALIDITY ' . ($mailbox->{'uid_valid'} || 0) . ']', 'Valid UIDs');
	$self->send_untagged('OK', '[UIDNEXT ' . ($mailbox->{'uid_next'} || 0) . ']', 'Predicted next UID');
	$self->send_untagged('FLAGS', '(\Answered \Flagged \Deleted \Seen \Draft)');
}

=head2 request_examine

Select a mailbox, in readonly mode.

=cut

sub request_examine {
	my $self = shift;
	my %args = @_;
	unless($self->is_authenticated) {
		return $self->send_tagged($args{id}, 'NO', 'Not authorized.');
	}
	if(my $mailbox = $self->select_mailbox(mailbox => $args{param}, readonly => 1)) {
		$self->send_mailbox_info($mailbox);
		$self->send_tagged($args{id}, 'OK', 'Mailbox selected.');
	} else {
		$self->send_tagged($args{id}, 'NO', 'Mailbox not found.');
	}
}

=head2 request_create

Create a new mailbox.

=cut

sub request_create {
	my $self = shift;
	my %args = @_;
	unless($self->is_authenticated) {
		return $self->send_tagged($args{id}, 'NO', 'Not authorized.');
	}
	if(my $mailbox = $self->create_mailbox(mailbox => $args{param})) {
		$self->send_tagged($args{id}, 'OK', 'Mailbox created.');
	} else {
		$self->send_tagged($args{id}, 'NO', 'Unable to create mailbox.');
	}
}

=head2 request_delete

Delete a given mailbox.

=cut

sub request_delete {
	my $self = shift;
	my %args = @_;
	unless($self->is_authenticated) {
		return $self->send_tagged($args{id}, 'NO', 'Not authorized.');
	}
	if(my $mailbox = $self->delete_mailbox(mailbox => $args{param})) {
		$self->send_tagged($args{id}, 'OK', 'Mailbox deleted.');
	} else {
		$self->send_tagged($args{id}, 'NO', 'Unable to delete mailbox.');
	}
}

=head2 request_rename

Request renaming a mailbox to something else.

=cut

sub request_rename {
	my $self = shift;
	my %args = @_;
	unless($self->is_authenticated) {
		return $self->send_tagged($args{id}, 'NO', 'Not authorized.');
	}
	my ($src, $dst) = split ' ', $args{param}, 2;
	if(my $mailbox = $self->rename_mailbox(mailbox => $src, target => $dst)) {
		$self->send_tagged($args{id}, 'OK', 'Mailbox renamed.');
	} else {
		$self->send_tagged($args{id}, 'NO', 'Unable to rename mailbox.');
	}
}

=head2 request_subscribe

Ask to subscribe to a mailbox.

=cut

sub request_subscribe {
	my $self = shift;
	my %args = @_;
	unless($self->is_authenticated) {
		return $self->send_tagged($args{id}, 'NO', 'Not authorized.');
	}
	if(my $mailbox = $self->subscribe_mailbox(mailbox => $args{param})) {
		$self->send_tagged($args{id}, 'OK', 'Subscribed to mailbox.');
	} else {
		$self->send_tagged($args{id}, 'NO', 'Unable to subscribe to mailbox.');
	}
}

=head2 request_unsubscribe

Ask to unsubscribe from a mailbox.

=cut

sub request_unsubscribe {
	my $self = shift;
	my %args = @_;
	unless($self->is_authenticated) {
		return $self->send_tagged($args{id}, 'NO', 'Not authorized.');
	}
	if(my $mailbox = $self->unsubscribe_mailbox(mailbox => $args{param})) {
		$self->send_tagged($args{id}, 'OK', 'Unsubscribed from mailbox.');
	} else {
		$self->send_tagged($args{id}, 'NO', 'Unable to unsubscribe from mailbox.');
	}
}

=head2 request_list

List mailboxes matching a specification.

=cut

sub request_list {
	my $self = shift;
	my %args = @_;
	unless($self->is_authenticated) {
		return $self->send_tagged($args{id}, 'NO', 'Not authorized.');
	}
	if(my $status = $self->list_mailbox(mailbox => $args{param})) {
		$self->send_tagged($args{id}, 'OK', 'List completed.');
	} else {
		$self->send_tagged($args{id}, 'NO', 'Failed to list mailboxes.');
	}
}

=head2 request_lsub

List subscriptions matching a spec - see L<request_list> for more details on how this is implemented.

=cut

sub request_lsub {
	my $self = shift;
	my %args = @_;
	unless($self->is_authenticated) {
		return $self->send_tagged($args{id}, 'NO', 'Not authorized.');
	}
	if(my $status = $self->list_subscription(mailbox => $args{param})) {
		$self->send_tagged($args{id}, 'OK', 'List completed.');
	} else {
		$self->send_tagged($args{id}, 'NO', 'Failed to list subscriptions.');
	}
}

=head2 on_multi_line

Called when we have multi-line data (fixed size in characters).

=cut

sub on_multi_line {
	my ($self, $data) = @_;

	if($self->{multiline}->{remaining}) {
		$self->{multiline}->{buffer} .= $data;
		$self->{multiline}->{remaining} -= length($data);
	} else {
		$self->{multiline}->{on_complete}->($self->{multiline}->{buffer});
		delete $self->{multiline};
	}
	return $self;
}

=head2 on_single_line

Called when there's more data to process for a single-line (standard mode) response.

=cut

sub on_single_line {
	my ($self, $data) = @_;

	$data =~ s/[\r\n]+//g;
	$self->debug("Had [$data]");
	$self->read_command($data);
	return 1;
}

sub is_multi_line { shift->{multiline} ? 1 : 0 }

=head2 configure

Set up any callbacks that were available.

=cut

sub configure {
	my $self = shift;
	my %args = @_;
	foreach (Protocol::IMAP::STATE_HANDLERS, qw{on_idle_update}) {
		$self->{$_} = delete $args{$_} if exists $args{$_};
	}
	$self->{capabilities} = [qw{IMAP4rev1 IDLE AUTH=LOGIN AUTH=PLAIN}];
	return %args;
}

=head2 add_capability

Add a new capability to the reported list.

=cut

sub add_capability {
	my $self = shift;
	push @{$self->{capabilities}}, @_;
}

=head2 validate_user

Validate the given user and password information, returning true if they have logged in successfully
and false if they are invalid.

=cut

sub validate_user {
	my $self = shift;
	my %args = @_;
	return 0;
}

=head2 select_mailbox

Selects the given mailbox.

Expects a hashref indicating mailbox information, e.g.:

 my $mailbox = {
 	name => $args{mailbox},
 	exists => 17,
 	recent => 2,
 };
 return $mailbox;

=cut

sub select_mailbox {
	my $self = shift;
	my %args = @_;
	return;
}

=head2 create_mailbox

Creates the given mailbox on the server.

=cut

sub create_mailbox {
	my $self = shift;
	my %args = @_;
}

=head2 delete_mailbox

Deletes the given mailbox.

=cut

sub delete_mailbox {
	my $self = shift;
	my %args = @_;
}

=head2 rename_mailbox

Renames the given mailbox.

=cut

sub rename_mailbox {
	my $self = shift;
	my %args = @_;
}

=head2 subscribe_mailbox

Adds the given mailbox to the active subscription list.

=cut

sub subscribe_mailbox {
	my $self = shift;
	my %args = @_;
}

=head2 unsubscribe_mailbox

Removes the given mailbox from the current user's subscription list.

=cut

sub unsubscribe_mailbox {
	my $self = shift;
	my %args = @_;
}

=head2 list_mailbox

List mailbox information given a search spec.

=cut

sub list_mailbox {
	my $self = shift;
	my %args = @_;
}

=head2 list_subscription

List subscriptions given a search spec.

=cut

sub list_subscription {
	my $self = shift;
	my %args = @_;
}

1;
