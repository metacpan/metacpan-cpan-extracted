#!/usr/bin/env perl
# Example: Twilio-compatible LAML migration -- phone numbers, messaging, calls,
# conferences, queues, recordings, project tokens, PubSub/Chat, and logs.
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID   - your SignalWire project ID
#   SIGNALWIRE_API_TOKEN    - your SignalWire API token
#   SIGNALWIRE_SPACE        - your SignalWire space

use strict;
use warnings;
use lib 'lib';
use SignalWire::REST::RestClient;
use JSON qw(encode_json);

my $client = SignalWire::REST::RestClient->new(
    project => $ENV{SIGNALWIRE_PROJECT_ID} // die("Set SIGNALWIRE_PROJECT_ID\n"),
    token   => $ENV{SIGNALWIRE_API_TOKEN}  // die("Set SIGNALWIRE_API_TOKEN\n"),
    host    => $ENV{SIGNALWIRE_SPACE}      // die("Set SIGNALWIRE_SPACE\n"),
);

sub safe {
    my ($label, $fn) = @_;
    my $result = eval { $fn->() };
    if ($@) {
        print "  $label: failed ($@)\n";
        return undef;
    }
    print "  $label: OK\n";
    return $result;
}

# --- Compat Phone Numbers ---

# 1. Search available numbers
print "Searching compat phone numbers...\n";
safe('Search local',     sub { $client->compat->phone_numbers->search_local('US', AreaCode => '512') });
safe('Search toll-free', sub { $client->compat->phone_numbers->search_toll_free('US') });
safe('List countries',   sub { $client->compat->phone_numbers->list_available_countries });

# 2. Purchase a number (demo)
print "\nPurchasing compat number...\n";
my $num = safe('Purchase', sub {
    $client->compat->phone_numbers->purchase(PhoneNumber => '+15125551234');
});
my $num_sid = $num ? $num->{sid} : undef;

# --- LaML Bin & Application ---

# 3. Create a LaML bin and application
print "\nCreating LaML resources...\n";
my $laml = safe('LaML bin', sub {
    $client->compat->laml_bins->create(
        Name     => 'Hold Music',
        Contents => '<Response><Say>Please hold.</Say></Response>',
    );
});
my $laml_sid = $laml ? $laml->{sid} : undef;

my $app = safe('Application', sub {
    $client->compat->applications->create(
        FriendlyName => 'Demo App',
        VoiceUrl     => 'https://example.com/voice',
    );
});
my $app_sid = $app ? $app->{sid} : undef;

# --- Messaging ---

# 4. Send an SMS
print "\nMessaging operations...\n";
my $msg = safe('Send SMS', sub {
    $client->compat->messages->create(
        From => '+15559876543',
        To   => '+15551234567',
        Body => 'Hello from SignalWire!',
    );
});
my $msg_sid = $msg ? $msg->{sid} : undef;

# 5. List and get messages
safe('List messages', sub { $client->compat->messages->list });
if ($msg_sid) {
    safe('Get message', sub { $client->compat->messages->get($msg_sid) });
    safe('List media',  sub { $client->compat->messages->list_media($msg_sid) });
}

# --- Calls ---

# 6. Outbound call
print "\nCall operations...\n";
my $call = safe('Create call', sub {
    $client->compat->calls->create(
        From => '+15559876543',
        To   => '+15551234567',
        Url  => 'https://example.com/voice-handler',
    );
});
my $call_sid = $call ? $call->{sid} : undef;

if ($call_sid) {
    safe('Start recording', sub { $client->compat->calls->start_recording($call_sid) });
    safe('Start stream', sub {
        $client->compat->calls->start_stream($call_sid, Url => 'wss://example.com/stream');
    });
}

# --- Conferences ---

# 7. Conference operations
print "\nConference operations...\n";
my $confs = safe('List conferences', sub { $client->compat->conferences->list });
my $conf_sid;
if ($confs && $confs->{data} && @{ $confs->{data} }) {
    $conf_sid = $confs->{data}[0]{sid};
}
if ($conf_sid) {
    safe('Get conference',     sub { $client->compat->conferences->get($conf_sid) });
    safe('List participants',  sub { $client->compat->conferences->list_participants($conf_sid) });
    safe('List conf recordings', sub { $client->compat->conferences->list_recordings($conf_sid) });
}

# --- Queues ---

# 8. Queue operations
print "\nQueue operations...\n";
my $queue = safe('Create queue', sub {
    $client->compat->queues->create(FriendlyName => 'compat-support-queue');
});
my $q_sid = $queue ? $queue->{sid} : undef;

if ($q_sid) {
    safe('List queue members', sub { $client->compat->queues->list_members($q_sid) });
}

# --- Recordings & Transcriptions ---

# 9. Recordings
print "\nRecordings and transcriptions...\n";
my $recs = safe('List recordings', sub { $client->compat->recordings->list });
my $first_rec_sid;
if ($recs && $recs->{data} && @{ $recs->{data} }) {
    $first_rec_sid = $recs->{data}[0]{sid};
}
if ($first_rec_sid) {
    safe('Get recording', sub { $client->compat->recordings->get($first_rec_sid) });
}

my $trans = safe('List transcriptions', sub { $client->compat->transcriptions->list });
my $first_trans_sid;
if ($trans && $trans->{data} && @{ $trans->{data} }) {
    $first_trans_sid = $trans->{data}[0]{sid};
}
if ($first_trans_sid) {
    safe('Get transcription', sub { $client->compat->transcriptions->get($first_trans_sid) });
}

# --- Faxes ---

# 10. Fax operations
print "\nFax operations...\n";
my $fax = safe('Create fax', sub {
    $client->compat->faxes->create(
        From     => '+15559876543',
        To       => '+15551234567',
        MediaUrl => 'https://example.com/document.pdf',
    );
});
my $fax_sid = $fax ? $fax->{sid} : undef;
if ($fax_sid) {
    safe('Get fax', sub { $client->compat->faxes->get($fax_sid) });
}

# --- Compat Accounts & Tokens ---

# 11. Accounts and tokens
print "\nAccounts and compat tokens...\n";
safe('List accounts', sub { $client->compat->accounts->list });
my $compat_token = safe('Create compat token', sub {
    $client->compat->tokens->create(name => 'demo-token');
});
if ($compat_token && $compat_token->{id}) {
    safe('Delete compat token', sub { $client->compat->tokens->delete($compat_token->{id}) });
}

# --- Project Tokens ---

# 12. Project token management
print "\nProject tokens...\n";
my $proj_token = safe('Create project token', sub {
    $client->project_ns->tokens->create(
        name        => 'CI Token',
        permissions => ['calling', 'messaging', 'video'],
    );
});
if ($proj_token && $proj_token->{id}) {
    safe('Update project token', sub {
        $client->project_ns->tokens->update($proj_token->{id}, name => 'CI Token (updated)');
    });
    safe('Delete project token', sub {
        $client->project_ns->tokens->delete($proj_token->{id});
    });
}

# --- PubSub & Chat Tokens ---

# 13. PubSub and Chat tokens
print "\nPubSub and Chat tokens...\n";
safe('PubSub token', sub {
    $client->pubsub->create_token(
        channels => { notifications => { read => JSON::true, write => JSON::true } },
        ttl      => 3600,
    );
});
safe('Chat token', sub {
    $client->chat->create_token(
        member_id => 'user-alice',
        channels  => { general => { read => JSON::true, write => JSON::true } },
        ttl       => 3600,
    );
});

# --- Logs ---

# 14. Log queries
print "\nQuerying logs...\n";
safe('Message logs',    sub { $client->logs->messages->list });
safe('Voice logs',      sub { $client->logs->voice->list });
safe('Fax logs',        sub { $client->logs->fax->list });
safe('Conference logs', sub { $client->logs->conferences->list });

my $voice_logs = safe('Voice log list', sub { $client->logs->voice->list }) // {};
my $first_voice = ($voice_logs->{data} // [{}])->[0] // {};
if ($first_voice->{id}) {
    safe('Voice log detail', sub { $client->logs->voice->get($first_voice->{id}) });
    safe('Voice log events', sub { $client->logs->voice->list_events($first_voice->{id}) });
}

# --- Clean up ---
print "\nCleaning up...\n";
safe('Delete queue',       sub { $client->compat->queues->delete($q_sid) })       if $q_sid;
safe('Delete application', sub { $client->compat->applications->delete($app_sid) }) if $app_sid;
safe('Delete LaML bin',    sub { $client->compat->laml_bins->delete($laml_sid) })   if $laml_sid;
safe('Delete number',      sub { $client->compat->phone_numbers->delete($num_sid) }) if $num_sid;
