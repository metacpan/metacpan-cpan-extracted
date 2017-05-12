# ABSTRACT: Off-the-Record secure messaging protocol
package Protocol::OTR;
BEGIN {
  $Protocol::OTR::AUTHORITY = 'cpan:AJGB';
}
$Protocol::OTR::VERSION = '0.05';
use strict;
use warnings;

use Alien::OTR;
use Alien::GCrypt;
use Alien::GPG::Error;
use Carp qw( croak );
use Protocol::OTR::Account ();
use Params::Validate qw(validate validate_pos SCALAR);

require Exporter;

require XSLoader;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'policies' => [ qw(
        POLICY_OPPORTUNISTIC
        POLICY_ALWAYS
    ) ],
    'error_codes' => [ qw(
        ERRCODE_NONE
        ERRCODE_ENCRYPTION_ERROR
        ERRCODE_MSG_NOT_IN_PRIVATE
        ERRCODE_MSG_UNREADABLE
        ERRCODE_MSG_MALFORMED
    ) ],
    'event_codes' => [ qw(
        MSGEVENT_NONE
        MSGEVENT_ENCRYPTION_REQUIRED
        MSGEVENT_ENCRYPTION_ERROR
        MSGEVENT_CONNECTION_ENDED
        MSGEVENT_SETUP_ERROR
        MSGEVENT_MSG_REFLECTED
        MSGEVENT_MSG_RESENT
        MSGEVENT_RCVDMSG_NOT_IN_PRIVATE
        MSGEVENT_RCVDMSG_UNREADABLE
        MSGEVENT_RCVDMSG_MALFORMED
        MSGEVENT_LOG_HEARTBEAT_RCVD
        MSGEVENT_LOG_HEARTBEAT_SENT
        MSGEVENT_RCVDMSG_GENERAL_ERR
        MSGEVENT_RCVDMSG_UNENCRYPTED
        MSGEVENT_RCVDMSG_UNRECOGNIZED
        MSGEVENT_RCVDMSG_FOR_OTHER_INSTANCE
    ) ],
    'smp_event_codes' => [ qw(
        SMPEVENT_NONE
        SMPEVENT_CHEATED
        SMPEVENT_IN_PROGRESS
        SMPEVENT_SUCCESS
        SMPEVENT_FAILURE
        SMPEVENT_ABORT
        SMPEVENT_ERROR
    ) ],
    'instags' => [ qw(
        INSTAG_BEST
        INSTAG_RECENT
        INSTAG_RECENT_RECEIVED
        INSTAG_RECENT_SENT
    ) ],
);
$EXPORT_TAGS{'constants'} = [
    map { @$_ } @EXPORT_TAGS{qw(policies error_codes event_codes smp_event_codes instags)}
];

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'constants'} } );

our @EXPORT = qw();

XSLoader::load('Protocol::OTR', $Protocol::OTR::{VERSION} ?
        ${ $Protocol::OTR::{VERSION} } : ()
    );

sub new {
    my $class = shift;

    my %args = validate(
        @_,
        {
            privkeys_file => {
                type => SCALAR,
                optional => 1,
                default => 'otr.privkey',
            },
            contacts_file => {
                type => SCALAR,
                optional => 1,
                default => 'otr.fingerprints',
            },
            instance_tags_file => {
                type => SCALAR,
                optional => 1,
                default => 'otr.instance_tags',
            },
        }
    );

    my $self = Protocol::OTR::_new(
        @args{qw(privkeys_file contacts_file instance_tags_file)}
    );

    return $self;
}

sub account {
    my $self = shift;

    my ($name, $protocol) = validate_pos(
        @_,
        {
            type => SCALAR,
        },
        {
            type => SCALAR,
        }
    );

    return Protocol::OTR::Account->_new(
        $self,
        {
            name => $name,
            protocol => $protocol,
        }
    );
}

sub accounts {
    my ($self) = @_;

    return map {
        Protocol::OTR::Account->_new($self, $_)
    } @{ $self->_accounts() }
}

sub find_account {
    my $self = shift;

    my ($name, $protocol) = validate_pos(
        @_,
        {
            type => SCALAR,
        },
        {
            type => SCALAR,
        }
    );

    return Protocol::OTR::Account->_new(
        $self,
        {
            name => $name,
            protocol => $protocol,
        },
        1, # find only
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Protocol::OTR - Off-the-Record secure messaging protocol

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use Protocol::OTR qw( :constants );

    my $otr = Protocol::OTR->new(
        {
            privkeys_file => "otr.private_key",
            contacts_file => "otr.fingerprints",
            instance_tags_file => "otr.instance_tags",
        }
    );

    # find or create account
    my $alice = $otr->account('alice@domain', 'prpl-jabber');

    # find or create contact known by $alice
    my $bob = $alice->contact('bob@domain');

    # create secure channel to Bob
    my $channel = $bob->channel(
        {
            policy => ...,
            max_message_size => ...,
            on_write => sub { ... },
            on_read => sub { ... },
            on_gone_secure => sub { ... },
            on_gone_insecure => sub { ... },
            on_still_secure => sub { ... },
            on_unverified_fingerprint => sub { ... },
            on_symkey => sub { ... },
            on_timer => sub { ... },
            on_smp => sub { ... },
            on_error => sub { ... },
            on_event => sub { ... },
            on_smp_event => sub { ... },
            on_before_encrypt => sub { ... },
            on_after_decrypt => sub { ... },
            on_is_contact_logged_in => sub { ... },
        }
    );

    # establish private chat
    $channel->init();

    # encrypt message
    $channel->write("Hi Bob!");

    # finish all sessions
    $channel->finish();

=head1 DESCRIPTION

L<Protocol::OTR> provides bindings to L<Off-the-Record C library|https://otr.cypherpunks.ca/>
allowing to manage OTR setup and to communicate in secure way.

=head1 METHODS

=head2 new

    my $otr = Protocol::OTR->new(
        {
            privkeys_file => "otr.private_key",
            contacts_file => "otr.fingerprints",
            instance_tags_file => "otr.instance_tags",
        }
    );

Returns an context object using optionally specified files. If files do not exist, they
will be created when needed.

The example above shows the default filenames used.

=head2 find_account

    my $account = $otr->find_account( $name, $protocol );

Returns an account object L<Protocol::OTR::Account> if exists, otherwise C<undef>.

=head2 account

    my $account = $otr->account( $name, $protocol );

Returns an existing matching account object L<Protocol::OTR::Account> or creates new one.

Note: Generating new private key may take some time.

=head2 accounts

    my @accounts = $otr->accounts();

Returns a list of known account objects L<Protocol::OTR::Account>.

=head1 ENVIRONMENT VARIABLES

=head2 PROTOCOL_OTR_ENABLE_QUICK_RANDOM

    BEGIN { $ENV{PROTOCOL_OTR_ENABLE_QUICK_RANDOM} = 1; }
    use Protocol::OTR;

If exists in environment it will use much faster C</dev/urandom>, rather then more
secure, but slow C</dev/random>.

=head1 EXPORTED CONSTANTS

Constants are grouped in four groups, to import them all use C<:constants>.

=head2 :policies

See L<Protocol::OTR::Channel/policy> for usage details.

=head3 POLICY_OPPORTUNISTIC

Start OTR conversation whenever it detects that the correspondent supports it. Default.

=head3 POLICY_ALWAYS

Requires encrypted conversation.

=head2 :error_codes

See L<Protocol::OTR::Channel/on_error> for usage details.

=head3 ERRCODE_NONE

=head3 ERRCODE_ENCRYPTION_ERROR

Error occured while encrypting a message.

=head3 ERRCODE_MSG_NOT_IN_PRIVATE

Sent encrypted message to somebody who is not in a mutual OTR session.

=head3 ERRCODE_MSG_UNREADABLE

Sent an unreadable encrypted message

=head3 ERRCODE_MSG_MALFORMED

Message sent is malformed.

=head2 :event_codes

See L<Protocol::OTR::Channel/on_event> for usage details.

=head3 MSGEVENT_NONE

=head3 MSGEVENT_ENCRYPTION_REQUIRED

Our policy requires encryption but we are trying to send an unencrypted message
out.

=head3 MSGEVENT_ENCRYPTION_ERROR

An error occured while encrypting a message and the message was not sent.

=head3 MSGEVENT_CONNECTION_ENDED

Message has not been sent because our buddy has ended the private conversation.
We should either close the connection, or refresh it.

=head3 MSGEVENT_SETUP_ERROR

A private conversation could not be set up. Error message will be passed.

=head3 MSGEVENT_MSG_REFLECTED

Received our own OTR messages.

=head3 MSGEVENT_MSG_RESENT

The previous message was resent.

=head3 MSGEVENT_RCVDMSG_NOT_IN_PRIVATE

Received an encrypted message but cannot read it because no private connection
is established yet.

=head3 MSGEVENT_RCVDMSG_UNREADABLE

Cannot read the received message.

=head3 MSGEVENT_RCVDMSG_MALFORMED

The message received contains malformed data.

=head3 MSGEVENT_LOG_HEARTBEAT_RCVD

Received a heartbeat.

=head3 MSGEVENT_LOG_HEARTBEAT_SENT

Sent a heartbeat.

=head3 MSGEVENT_RCVDMSG_GENERAL_ERR

Received a general OTR error. Error message will be passed.

=head3 MSGEVENT_RCVDMSG_UNENCRYPTED

Received an unencrypted message. The unencrypted message will be passed.

=head3 MSGEVENT_RCVDMSG_UNRECOGNIZED

Cannot recognize the type of OTR message received.

=head3 MSGEVENT_RCVDMSG_FOR_OTHER_INSTANCE

Received and discarded a message intended for another instance.

=head2 :smp_event_codes

See L<Protocol::OTR::Channel/on_smp_event> for usage details.

=head3 SMPEVENT_NONE

=head3 SMPEVENT_CHEATED

The current verification has been aborted, use progress percent to update auth
progress dialog.

=head3 SMPEVENT_IN_PROGRESS

=head3 SMPEVENT_SUCCESS

=head3 SMPEVENT_FAILURE

=head3 SMPEVENT_ABORT

Update the auth progress dialog with progress percent

=head3 SMPEVENT_ERROR

Same as L</SMPEVENT_CHEATED>.

=head2 :instags

See L<Protocol::OTR::Channel/select_session> for usage details.

=head3 INSTAG_BEST

Session that has the best conversation status, then fingerprint status (in the
event of a tie), then most recent (similarly in the event of a tie). When
calculating how recent an instance has been active, C<INSTAG_BEST> is limited
by a one second resolution.

=head3 INSTAG_RECENT

The most recent session (either by message sent or received).

=head3 INSTAG_RECENT_RECEIVED

The session with the most recent message received.

=head3 INSTAG_RECENT_SENT

The session with the most recent message sent.

=head1 SEE ALSO

=over 4

=item * L<https://otr.cypherpunks.ca/>

=item * L<Protocol::OTR::Account>

=item * L<Protocol::OTR::Contact>

=item * L<Protocol::OTR::Fingerprint>

=item * L<Protocol::OTR::Channel>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
