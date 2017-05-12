# ABSTRACT: Off-the-Record communication Channel
package Protocol::OTR::Channel;
BEGIN {
  $Protocol::OTR::Channel::AUTHORITY = 'cpan:AJGB';
}
$Protocol::OTR::Channel::VERSION = '0.05';
use strict;
use warnings;
use Scalar::Util ();
use Protocol::OTR ();

sub _new {
    my ($class, $cnt, $args) = @_;

    $args->{selected_instag} = Protocol::OTR::INSTAG_BEST();
    $args->{known_sessions} = {};
    $args->{gone_secure} = 0;

    my $self = bless $args, $class;
    $self->{cnt} = $cnt;

    return $self;
}

sub account {
    return $_[0]->{cnt}->{act};
}

sub contact {
    return $_[0]->{cnt};
}

sub _ev {
    my ($self, $cb_name) = (shift, shift);

    {
        Scalar::Util::weaken(my $this = $self);
        $this->{$cb_name}->($this, @_);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Protocol::OTR::Channel - Off-the-Record communication Channel

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

=head1 DESCRIPTION

L<Protocol::OTR::Channel> represents the OTR communication channel.

=head1 METHODS

=head2 account

    my $account = $channel->account();

Returns channel's L<Protocol::OTR::Account> object.

=head2 contact

    my $contact = $channel->contact();

Returns channel's L<Protocol::OTR::Contact> object.

=head2 init

    $channel->init();

Send OTR default query message to initialize secure session.

    '<b>'. $channel->account->name .'</b> has requested an '
   .'<a href="http://otr.cypherpunks.ca/">Off-the-Record '
   .'private conversation</a>.  However, you do not have a plugin '
   .'to support that.\nSee <a href="http://otr.cypherpunks.ca/">'
   .'http://otr.cypherpunks.ca/</a> for more information.'

=head2 refresh

    $channel->refresh();

Refreshes current authentication keys.

=head2 finish

    $channel->finish();

Finish all sessions within the channel.

=head2 status

    print $channel->status();

Returns current status of the channel, which is one of:

=over 4

=item * Unused

=item * Not private

=item * Unverified

=item * Private

=item * Finished

=back

=head2 create_symkey

    my $symkey = $channel->create_symkey( $use, $use_for );

Returns symmetric key agreed with other party. C<$use> is an integer (1 is
reserved for future support of file transfers), while C<$use_for> is a
message how the symmetric key will be used.

Generate key for symmetric encryption:

    # Alice
    my $crypt_cipher = "Blowfish";
    my $crypt_key = $channel->create_symkey( 2, $crypt_cipher );
    my $crypt = Crypt::CBC->new(
        -key => $crypt_key,
        -cipher => $crypt_cipher,
    );

    # Bob
    on_symkey => sub {
        my ($c, $symkey, $use, $use_for) = @_;

        my $crypt_cipher = $use_for;
        my $crypt_key = $symkey;

        my $crypt = Crypt::CBC->new(
            -key => $crypt_key,
            -cipher => $crypt_cipher,
        );
    }

=head2 ping

    $channel->ping();

Call this function every so often, either as directed by the L</on_timer>
callback or every minute if the callback is not implemented.

See L</on_timer> for more details.

=head2 smp_verify

    $channel->smp_verify( $answer, [ $question ]);

Verify identity of the contact using Socialist Millionaires' Protocol (SMP).
Contact is required to respond with the expected C<$answer>, optional
C<$question> may be provided.

=head2 smp_respond

    sub display_smp_popup {
        my ($channel, $question) = @_;

        my $answer = get_answer($question);

        $channel->smp_respond( $answer );
    }

Respond to SMP identity verification question with expected secret/answer.

=head2 smp_abort

    $channel->smp_abort();

Abort the SMP when error occured.

=head2 write

    $channel->write( $message );

Send message over the secure channel. The encrypted message ready for sending
will be passed to L</on_write> callback to transport.

=head2 read

    $channel->read( $input );

Handle a message just received from the network.  It is safe to pass all
received messages to this routine. Decrypted messages will be passed to
L</on_read> callback.

=head2 sessions

    my @sessions = $channel->sessions();

Returns a list of session IDs (instags) that were used by the contact in
this channel.

=head2 current_session

    my $current_session_id = $channel->current_session();

Returns currently used by the contact session ID (instag) in this channel.

=head2 select_session

    $channel->select_session( $id );

Selects provided session id as the current session. Returns false if session id
is not known.

One of special session selectors (exported via L<Protocol::OTR/:instags>) can be also used.

=head1 CALLBACKS AND OPTIONS

    my $channel = $contact->channel(
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

=head2 policy

    my $channel = $contact->channel(
        {
            policy => POLICY_OPPORTUNISTIC,
            ...
        }
    );

Select the default OTR policy, see L<Protocol::OTR/:policies> for details.

=head2 max_message_size

    my $channel = $contact->channel(
        {
            max_message_size => 10 * 1024,
            ...
        }
    );

Define the maximum message size handled by protocol. Messages larger then this
value will be split and delivered separetely.

Following defaults are used based on the protocol:

=over 4

=item * prpl-msn: 1409

=item * prpl-icq: 2346

=item * prpl-aim: 2343

=item * prpl-yahoo: 799

=item * prpl-gg: 1999

=item * prpl-irc: 417

=item * prpl-oscar: 2343

=back

=head2 on_write

    my $channel = $contact->channel(
        {
            on_write => sub {
                my ($c, $message) = @_;

                $transporter->deliver( $c->contact->name, $message );
            },
            ...
        }
    );

Receives encrypted message to be sent. This callback is required.

C<$c> is a reference to the current channel.

C<$message> is the encrypted message to be sent.

=head2 on_read

    $channel->read( $raw_message );

    my $channel = $contact->channel(
        {
            on_read => sub {
                my ($c, $message) = @_;

                print "From: ",     $c->contact->name, "\n";
                print "To: ",       $c->account->name, "\n";
                print "Message:\n", $message,          "\n";
            },
            ...
        }
    );

Receives decrypted messages. This callback is required.

C<$c> is a reference to the current channel.

C<$message> is the received message.

Note: internal protocol messages are not received by this callback.

=head2 on_gone_secure

    my $channel = $contact->channel(
        {
            on_gone_secure => sub {
                my ($c) = @_;

                print "Channel between ", $c->contact->name , " and ",
                       $c->account->name, " is now secure\n";

                my $fp = $c->contact->active_fingerprint;
                unless ( $fp->is_verified ) {
                    print "Fingerprint ", $fp->hash, " is not verified\n";
                }
            },
            ...
        }
    );

Called when the channel has entered secure state.

C<$c> is a reference to the current channel.

=head2 on_gone_insecure

    my $channel = $contact->channel(
        {
            on_gone_insecure => sub {
                my ($c) = @_;

                print "Channel between ", $c->contact->name , " and ",
                       $c->account->name, " is not secure anymore\n";
            },
            ...
        }
    );

Called when the channel has left secure state.

C<$c> is a reference to the current channel.

=head2 on_still_secure

    my $channel = $contact->channel(
        {
            on_still_secure => sub {
                my ($c) = @_;

                print "Channel between ", $c->contact->name , " and ",
                       $c->account->name, " is still secure\n";
            },
            ...
        }
    );

Called when the channel has entered secure state using already known D-H keys.

C<$c> is a reference to the current channel.

=head2 on_unverified_fingerprint

    my $channel = $contact->channel(
        {
            on_unverified_fingerprint => sub {
                my ($c, $fingerprint_hash, $seen_before) = @_;

                print "Unverified fingerprint ", $fingerprint_hash,
                      " from ", $c->contact->name ,
                      " to ", $c->account->name,
                      " is ", ( $seen_before ?
                                "unrecognised" :
                                "not authenticated"
                              ), "\n";
            },
            ...
        }
    );

Called when new fingerprint has been received.

C<$c> is a reference to the current channel.

C<$fingerprint_hash> is the human readable hash of the fingerprint.

C<$seen_before> is a boolean indicating if the fingerprint was seen before.

=head2 on_symkey

    my $channel = $contact->channel(
        {
            on_symkey => sub {
                my ($c, $symkey, $use, $use_for) = @_;

                print "Received symmetric key for ", $use_for, " (", $use,") ",
                      " from ", $c->contact->name , " to ", $c->account->name,
                      ":\n", unpack("H*", $symkey), "\n";

                encrypt_file( $symkey );
            },
            ...
        }
    );

Called when received symmetric key from our contact. Example use is as password
to archive file.

C<$c> is a reference to the current channel.

C<$symkey> is the symmetric key.

C<$use> is the numeric code of the requested use (use numbers E<gt> 1).

C<$use_for> is the use specific data.

=head2 on_timer

    my $channel = $contact->channel(
        {
            on_timer => sub {
                my ($c, $interval) = @_;

                undef $ping_timer;

                if ( $interval > 0 ) {
                    $ping_timer = AE::timer 0, $interval, sub {
                        $c->ping();
                    };
                }
            },
            ...
        }
    );

When called, turn off any existing periodic timer.

Additionally, if interval > 0, set a new periodic timer to go off every
C<$interval> seconds.  When that timer fires, you must call L</ping> method.

The timing does not have to be exact; this timer is used to provide
forward secrecy by cleaning up stale private state that may otherwise
stick around in memory.  Note that the C<on_timer> callback may be invoked
from L</ping> itself, possibly to indicate that C<$interval> == 0 (that is, that
there's no more periodic work to be done at this time).

If you set this callback is not provided, then you must ensure that your
application calls L</ping> every minute.  The advantage of
implementing the C<on_timer> callback is that the timer can be
turned on by the library only when it's needed.

It is not a problem (except for a minor performance hit) to call
L</ping> more often than requested, whether C<on_timer> is implemented or not.

If you fail to implement the C<on_timer> callback, and also fail to
periodically call L</ping>, then you open your users to a possible forward
secrecy violation: an attacker that compromises the user's computer may be
able to decrypt a handful of long-past messages (the first messages of an
OTR conversation).

C<$c> is a reference to the current channel.

C<$interval> is described above.

=head2 on_smp

    my $channel = $contact->channel(
        {
            on_smp => sub {
                my ($c, $question) = @_;

                print "SMP verification in channel between ", $c->contact->name,
                      " and ", $c->account->name, "\n";

                display_smp_popup( $c, $question );
            },
            ...
        }
    );

Called when received SMP verification. Use to retrieve the answer.

C<$c> is a reference to the current channel.

C<$question> is an optional question/hint.

=head2 on_error

    my $channel = $contact->channel(
        {
            on_error => sub {
                my ($c, $error_code) = @_;

                print "Handling error in channel between ", $c->contact->name,
                      " and ", $c->account->name, "\n";

                handle_error( $c, $error_code );
            },
            ...
        }
    );

Called when error occured in the channel. See L<Protocol::OTR/:error_codes> for
possible errors.

C<$c> is a reference to the current channel.

C<$error_code> is the numeric code of error.

=head2 on_event

    my $channel = $contact->channel(
        {
            on_event => sub {
                my ($c, $event_code, $message) = @_;

                print "Handling event in channel between ", $c->contact->name,
                      " and ", $c->account->name, "\n";

                handle_event( $c, $event_code, $message );
            },
            ...
        }
    );

Called when event occured in the channel. See L<Protocol::OTR/:event_codes> for
possible events.

C<$c> is a reference to the current channel.

C<$event_code> is the numeric code of event.

C<$message> is set only for following events: C<MSGEVENT_SETUP_ERROR>,
C<MSGEVENT_RCVDMSG_GENERAL_ERR>, C<MSGEVENT_RCVDMSG_UNENCRYPTED>.

=head2 on_smp_event

    my $channel = $contact->channel(
        {
            on_smp_event => sub {
                my ($c, $smp_event_code, $progress) = @_;

                print "Handling SMP event (progress at ", $progress, "%) ",
                      "in channel between ", $c->contact->name,
                      " and ", $c->account->name, "\n";

                handle_smp_event( $c, $smp_event_code, $progress );
            },
            ...
        }
    );

Called when SMP event occured in the channel. See L<Protocol::OTR/:smp_event_codes> for
possible events.

C<$c> is a reference to the current channel.

C<$smp_event_code> is the numeric code of SMP event.

C<$progress> indicates the overall progress of SMP verification process.

=head2 on_before_encrypt

    my $channel = $contact->channel(
        {
            on_before_encrypt => sub {
                my ($c, $message) = @_;

                return $translator->write( $message );
            },
            ...
        }
    );

Called immediately before a data message is encrypted.

C<$c> is a reference to the current channel.

C<$message> is the message to be sent.

=head2 on_after_decrypt

    my $channel = $contact->channel(
        {
            on_after_decrypt => sub {
                my ($c, $message) = @_;

                return $translator->read( $message );
            },
            ...
        }
    );

Called immediately after a data message is decrypted.

C<$c> is a reference to the current channel.

C<$message> is the received message.

=head2 on_is_contact_logged_in

    my $channel = $contact->channel(
        {
            on_is_contact_logged_in => sub {
                my ($c) = @_;

                return 1;
            },
            ...
        }
    );

Report whether you think the given user is online.  Return 1 if yes, 0 if no,
-1 if unkown.

If you return 1, messages such as heartbeats or other notifications may be
sent to the user, which could result in "not logged in" errors if you're wrong.

C<$c> is a reference to the current channel.

=head1 SEE ALSO

=over 4

=item * L<Protocol::OTR>

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
