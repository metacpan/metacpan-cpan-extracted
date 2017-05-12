
use strict;
use warnings;

use Test::More;

BEGIN { $ENV{PROTOCOL_OTR_ENABLE_QUICK_RANDOM} = 1 }

use Protocol::OTR qw( :constants );
use File::Temp qw( tempdir );

my $tmpdir1 = tempdir( 'XXXXXXXX', DIR => "t/", CLEANUP => 1 );
my $tmpdir2 = tempdir( 'XXXXXXXX', DIR => "t/", CLEANUP => 1 );

my %FLAGS;
my %SWITCHES;
my %RWHANDLERS;

my @Q;

my $SMP_QUESTION = "W Paryżu najlepsze kasztany są na placu Pigalle";
my $SMP_WRONG_ANSWER = "Na placu Pigalle najlepsze są nie kasztany, ale burdele";
my $SMP_CORRECT_ANSWER = "Zuzanna lubi je tylko jesienią.";

# messages need to be sent/received in order
sub send_messages {
    my $action = shift || sub { 0 };
    my $result = $action->();
    while (my $e = shift @Q) {
        $e->();
    }

    return $result;
}

my $otr = Protocol::OTR->new(
    {
        privkeys_file => "$tmpdir1/otr.private_key",
        contacts_file => "$tmpdir1/otr.fingerprints",
        instance_tags_file => "$tmpdir1/otr.instance_tags",

    }
);

my $otr2 = Protocol::OTR->new(
    {
        privkeys_file => "$tmpdir2/otr.private_key",
        contacts_file => "$tmpdir2/otr.fingerprints",
        instance_tags_file => "$tmpdir2/otr.instance_tags",

    }
);

my ($msg_a2b, $msg_b2a);

my $alice = $otr->account('alice', "protocol");
my $bob = $otr2->account('bob', "protocol");

# alice has Bob's fingerprint from his business card
my $alice2bob = $alice->contact( 'bob', '12345678 90ABCDEF 12345678 90ABCDEF 12345678');
# bob never talked with Alice over OTR
my $bob2alice = $bob->contact('alice');

my @alice2bob_fingerprints = $alice2bob->fingerprints();
is(scalar @alice2bob_fingerprints, 1, "Alice knows Bob's fingerprint");

my @bob2alice_fingerprints = $bob2alice->fingerprints();
is(scalar @bob2alice_fingerprints, 0, "Bob doesn't know Alice's fingerprint");

my %common_handlers = (
    policy => POLICY_ALWAYS,
    max_message_size => 1024,
    on_is_contact_logged_in => sub {
        my ($c) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $FLAGS{$slot}->{on_is_contact_logged_in} = 1;

        return 1;
    },
    on_before_encrypt => sub {
        my ($c, $message) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $FLAGS{$slot}->{on_before_encrypt} = {
            message => $message,
        };

        return $message unless $SWITCHES{enable_convert};

        my $enc = reverse $message;

        return $enc;
    },
    on_after_decrypt => sub {
        my ($c, $message) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $FLAGS{$slot}->{on_after_decrypt} = {
            message => $message,
        };

        return $message unless $SWITCHES{enable_convert};

        my $dec = reverse $message;

        return $dec;
    },
    on_gone_secure => sub {
        my ($c) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $FLAGS{$slot}->{on_gone_secure} = 1;
    },
    on_gone_insecure => sub {
        my ($c) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $FLAGS{$slot}->{on_gone_insecure} = 1;
    },
    on_still_secure => sub {
        my ($c) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $FLAGS{$slot}->{on_gone_insecure} = 1;
    },
    on_unverified_fingerprint => sub {
        my ($c, $fingerprint_hash, $seen_before) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $FLAGS{$slot}->{on_unverified_fingerprint} = {
            hash => $fingerprint_hash,
            seen_before => $seen_before
        };
    },
    on_symkey => sub {
        my ($c, $symkey, $use, $use_for) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $FLAGS{$slot}->{on_symkey} = {
            symkey => $symkey,
            use => $use,
            use_for => $use_for,
        };
    },
    on_error => sub {
        my ($c, $error_code) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $FLAGS{$slot}->{on_error} = {
            code => $error_code,
        };
    },
    on_event => sub {
        my ($c, $event_code, $message) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $FLAGS{$slot}->{on_event} = {
            code => $event_code,
            message => $message,
        };
    },
    on_timer => sub {
        my ($c, $interval) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $FLAGS{$slot}->{on_timer} = {
            interval => $interval,
        };
    },
    on_smp_event => sub {
        my ($c, $smp_event_code, $progress) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $FLAGS{$slot}->{on_smp_event} = {
            code => $smp_event_code,
            progress => $progress,
        };
    },
    on_smp => sub {
        my ($c, $question) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $FLAGS{$slot}->{on_smp} = {
            question => $question,
        };
    },
    on_write => sub {
        my ($c, $message) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $RWHANDLERS{$slot}->{on_write}->( $message );
    },
    on_read => sub {
        my ($c, $message) = @_;

        my $slot = join('2', $c->account->name, $c->contact->name);

        $FLAGS{$slot}->{on_read} = {
            message => $message,
        };
    },
);

my $channel_alice2bob = $alice2bob->channel( {
        %common_handlers
    }
);

my $channel_bob2alice = $bob2alice->channel( {
        %common_handlers
    }
);

$RWHANDLERS{alice2bob}->{on_write} = sub {
    my ($msg) = @_;
    push @Q, sub {
        $channel_bob2alice->read( $msg );
    };
};

$RWHANDLERS{bob2alice}->{on_write} = sub {
    my ($msg) = @_;
    push @Q, sub {
        $channel_alice2bob->read( $msg );
    };
};

is($channel_alice2bob->status, "Not private", "Status of Alice's channel to Bob is Not private");
is($channel_bob2alice->status, "Not private", "Status of Bob's channel to Alice is Not private");

send_messages(
    sub {
        $channel_alice2bob->init();
    }
);

is($FLAGS{alice2bob}->{on_gone_secure}, 1, "Alice's channel is secure");
is($FLAGS{bob2alice}->{on_gone_secure}, 1, "Bob's channel is secure");

is($channel_alice2bob->status, "Unverified", "Status of Alice's channel to Bob is Unverified");
is($channel_alice2bob->contact->active_fingerprint->status, "Unverified", "...and so is active fingerprint");
is($channel_bob2alice->status, "Unverified", "Status of Bob's channel to Alice is Unverified");
is($channel_bob2alice->contact->active_fingerprint->status, "Unverified", "...and so is active fingerprint");

is($FLAGS{alice2bob}->{on_unverified_fingerprint}->{hash}, $bob->fingerprint, "Alice's learnt Bob's fingerprint");
is($FLAGS{alice2bob}->{on_unverified_fingerprint}->{seen_before}, 1, "...that was seen before");
is($FLAGS{bob2alice}->{on_unverified_fingerprint}->{hash}, $alice->fingerprint, "Bob's learnt Alice's fingerprint");
ok(! $FLAGS{bob2alice}->{on_unverified_fingerprint}->{seen_before}, "...that was not seen before");

is($alice2bob->active_fingerprint->hash, $bob->fingerprint, "Alice is using Bob's generated fingerprint");
is($bob2alice->active_fingerprint->hash, $alice->fingerprint, "Bob is using Alice's generated fingerprint");

@alice2bob_fingerprints = $alice2bob->fingerprints();
is(scalar @alice2bob_fingerprints, 2, "Alice learnt another Bob's fingerprint");

@bob2alice_fingerprints = $bob2alice->fingerprints();
is(scalar @bob2alice_fingerprints, 1, "Bob learnt Alice's fingerprint");

my $alice2bob_symkey = send_messages(
    sub {
        $channel_alice2bob->create_symkey(2, "testing unicode ążśźęćół");
    }
);
is($FLAGS{bob2alice}->{on_symkey}->{use}, 2, "Symkey's use = 2");
is($FLAGS{bob2alice}->{on_symkey}->{use_for}, "testing unicode ążśźęćół", "Symkey is used for testing unicode");
is($FLAGS{bob2alice}->{on_symkey}->{symkey}, $alice2bob_symkey, "Bob has received Alice's symkey");

my $bob2alice_symkey = send_messages(
    sub {
        $channel_bob2alice->create_symkey(3, "zip");
    }
);
is($FLAGS{alice2bob}->{on_symkey}->{use}, 3, "Symkey's use = 3");
is($FLAGS{alice2bob}->{on_symkey}->{use_for}, "zip", "Symkey is used for zip");
is($FLAGS{alice2bob}->{on_symkey}->{symkey}, $bob2alice_symkey, "Alice has received Bob's symkey");

is($FLAGS{alice2bob}->{on_gone_secure}, 1, "Alice's channel is secure");
is($FLAGS{bob2alice}->{on_gone_secure}, 1, "Bob's channel is secure");

%FLAGS = ();
send_messages(
    sub {
        $channel_bob2alice->finish();
    }
);

is($FLAGS{alice2bob}->{on_gone_insecure}, 1, "Alice's channel gone insecure");
is($FLAGS{alice2bob}->{on_event}->{code}, MSGEVENT_LOG_HEARTBEAT_RCVD, "Alice's channel received MSGEVENT_LOG_HEARTBEAT_RCVD ");
is($FLAGS{bob2alice}->{on_is_contact_logged_in}, 1, "Bob's checked if Alice is online");

is($channel_alice2bob->status, "Finished", "Status of Alice's channel to Bob is Finished");
is($channel_bob2alice->status, "Not private", "Status of Bob's channel to Alice is Not private");

%FLAGS = ();

send_messages(
    sub {
        $channel_bob2alice->init();
    }
);

$msg_a2b = "Hi Bob! It's Alice";

send_messages(
    sub {
        $channel_alice2bob->write( $msg_a2b );
    }
);

is($FLAGS{bob2alice}->{on_read}->{message}, $msg_a2b, "Bob got Alice's message");
is($FLAGS{alice2bob}->{on_before_encrypt}->{message}, $msg_a2b, "Alice had chance to transform message before sending");
is($FLAGS{bob2alice}->{on_after_decrypt}->{message}, $msg_a2b, "...Bob got that chance as well");

%FLAGS = ();
$SWITCHES{enable_convert} = 1;

$msg_b2a = "Is that really you?";

send_messages(
    sub {
        $channel_bob2alice->write( $msg_b2a );
    }
);

is($FLAGS{alice2bob}->{on_read}->{message}, $msg_b2a, "Alice got Bob's message");
is($FLAGS{bob2alice}->{on_before_encrypt}->{message}, $msg_b2a, "Bob had chance to transform message before sending");
is($FLAGS{alice2bob}->{on_after_decrypt}->{message}, scalar reverse($msg_b2a), "...and used it to reverse the message");

%FLAGS = ();

send_messages(
    sub {
        $channel_bob2alice->smp_verify( $SMP_CORRECT_ANSWER, $SMP_QUESTION );
    }
);

is($FLAGS{alice2bob}->{on_smp}->{question}, $SMP_QUESTION, "Alice's channel received SMP question, but she doesn't know the answer");

send_messages(
    sub {
        $channel_alice2bob->smp_respond( $SMP_WRONG_ANSWER );
    }
);
is($FLAGS{bob2alice}->{on_smp_event}->{code}, SMPEVENT_FAILURE, "...so Bob's channel received SMPEVENT_FAILURE ");
is($FLAGS{alice2bob}->{on_smp_event}->{code}, SMPEVENT_FAILURE, "...and so did Alice's channel");

%FLAGS = ();

send_messages(
    sub {
        $channel_bob2alice->smp_verify( $SMP_CORRECT_ANSWER );
    }
);

is($FLAGS{alice2bob}->{on_smp}->{question}, undef, "Alice's channel received SMP request, no hint given, but it is the right Alice");

send_messages(
    sub {
        $channel_alice2bob->smp_respond( $SMP_CORRECT_ANSWER );
    }
);
is($FLAGS{bob2alice}->{on_smp_event}->{code}, SMPEVENT_SUCCESS, "...so Bob's channel received SMPEVENT_SUCCESS ");
is($FLAGS{alice2bob}->{on_smp_event}->{code}, SMPEVENT_SUCCESS, "...and so did Alice's channel");

is($channel_alice2bob->status, "Private", "Status of Alice's channel to Bob is Private");
is($channel_alice2bob->contact->active_fingerprint->status, "Private", "...and so is active fingerprint");
is($channel_bob2alice->status, "Private", "Status of Bob's channel to Alice is Private");
is($channel_bob2alice->contact->active_fingerprint->status, "Private", "...and so is active fingerprint");


%FLAGS = ();

send_messages(
    sub {
        $channel_bob2alice->refresh();
    }
);

is($FLAGS{alice2bob}->{on_gone_secure}, 1, "Alice's channel gone secure");
is($FLAGS{bob2alice}->{on_gone_insecure}, 1, "Bob's channel gone insecure");
is($FLAGS{bob2alice}->{on_gone_secure}, 1, "Bob's channel gone secure");

my @alice_sessions = $channel_alice2bob->sessions();
my @bob_sessions = $channel_bob2alice->sessions();

ok((grep { $channel_alice2bob->current_session } @alice_sessions), "Alice's current session in the list of sessions");
ok((grep { $channel_bob2alice->current_session } @bob_sessions), "Bob's current session in the list of sessions");

ok (
    send_messages(
        sub {
            $channel_alice2bob->select_session( $channel_alice2bob->current_session );
        }
    ),
    "Alice sets to use her current session (rather then the default best one)"
);

ok (
    send_messages(
        sub {
            $channel_bob2alice->select_session( $channel_bob2alice->current_session );
        }
    ),
    "...and so does Bob"
);

%FLAGS = ();

$msg_b2a = "I'm using my current session";
send_messages(
    sub {
        $channel_bob2alice->write( $msg_b2a );
    }
);

is($FLAGS{alice2bob}->{on_read}->{message}, $msg_b2a, "Alice got Bob's message");
is($FLAGS{bob2alice}->{on_before_encrypt}->{message}, $msg_b2a, "Bob had chance to transform message before sending");
is($FLAGS{alice2bob}->{on_after_decrypt}->{message}, scalar reverse($msg_b2a), "...and used it to reverse the message");

%FLAGS = ();
send_messages(
    sub {
        $channel_alice2bob->finish();
    }
);

is($FLAGS{bob2alice}->{on_gone_insecure}, 1, "Bob's channel gone insecure");
is($FLAGS{bob2alice}->{on_event}->{code}, MSGEVENT_LOG_HEARTBEAT_RCVD, "Bob's channel received MSGEVENT_LOG_HEARTBEAT_RCVD ");
is($FLAGS{alice2bob}->{on_is_contact_logged_in}, 1, "Alice's checked if Bob is online");


%FLAGS = ();
send_messages(
    sub {
        $channel_bob2alice->finish();
    }
);

is(scalar keys %{$FLAGS{bob2alice}}, 0, "Bob's insecure channel doesn't send any messages");
is(scalar keys %{$FLAGS{alice2bob}}, 0, "Alice's channel was not contacted");

# TODO need to check it with otr-dev
$SWITCHES{enable_convert} = 0;

$msg_b2a = "I'm back!";
send_messages(
    sub {
        $channel_bob2alice->write( $msg_b2a );
    }
);
is($FLAGS{bob2alice}->{on_event}->{code}, MSGEVENT_ENCRYPTION_REQUIRED, "Bob's channel requires encryption");
is($FLAGS{bob2alice}->{on_gone_secure}, 1, "Bob's channel gone secure");

is($FLAGS{alice2bob}->{on_read}->{message}, $msg_b2a, "Alice got Bob's message (encrypted due to POLICY_ALWAYS)");
is($FLAGS{alice2bob}->{on_gone_secure}, 1, "Alice's channel gone secure");

%FLAGS = ();

$msg_a2b = "Plain text message";
$channel_bob2alice->read( $msg_a2b );

is($FLAGS{bob2alice}->{on_event}->{code}, MSGEVENT_RCVDMSG_UNENCRYPTED, "Bob's channel received unencrypted message");
is($FLAGS{bob2alice}->{on_event}->{message}, $msg_a2b, "...but still readable");

done_testing();

