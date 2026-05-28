#!/usr/bin/env perl
# Example: Call queues, recording review, and MFA verification.
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID   - your SignalWire project ID
#   SIGNALWIRE_API_TOKEN    - your SignalWire API token
#   SIGNALWIRE_SPACE        - your SignalWire space

use strict;
use warnings;
use lib 'lib';
use SignalWire::REST::RestClient;

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

# --- Queues ---

# 1. Create a queue
print "Creating call queue...\n";
my $queue_id;
my $queue = safe('Create queue', sub {
    $client->queues->create(name => 'Support Queue', max_size => 50);
});
$queue_id = $queue ? $queue->{id} : undef;

# 2. List queues
print "\nListing queues...\n";
my $queues = safe('List queues', sub { $client->queues->list });
if ($queues) {
    for my $q (@{ $queues->{data} // [] }) {
        print "  - $q->{id}: " . ($q->{friendly_name} // $q->{name} // 'unnamed') . "\n";
    }
}

# 3. Get and update queue
if ($queue_id) {
    my $detail = safe('Get queue', sub { $client->queues->get($queue_id) });
    if ($detail) {
        print "\nQueue detail: " . ($detail->{friendly_name} // 'N/A')
            . " (max: " . ($detail->{max_size} // 'N/A') . ")\n";
    }
    safe('Update queue', sub {
        $client->queues->update($queue_id, name => 'Priority Support Queue');
    });
}

# 4. Queue members
if ($queue_id) {
    print "\nListing queue members...\n";
    safe('List members', sub {
        my $members = $client->queues->list_members($queue_id);
        for my $m (@{ $members->{data} // [] }) {
            print "  - Member: " . ($m->{call_id} // $m->{id} // 'unknown') . "\n";
        }
    });
    safe('Next member', sub {
        my $next = $client->queues->get_next_member($queue_id);
        print "  Next member: " . (ref $next ? 'found' : $next) . "\n";
    });
}

# --- Recordings ---

# 5. List recordings
print "\nListing recordings...\n";
my $recordings = safe('List recordings', sub { $client->recordings->list });
if ($recordings) {
    my @data = @{ $recordings->{data} // [] };
    for my $r (@data[0 .. ($#data < 4 ? $#data : 4)]) {
        print "  - $r->{id}: " . ($r->{duration} // 'N/A') . "s\n";
    }
}

# 6. Get recording details
if ($recordings && $recordings->{data} && @{ $recordings->{data} }) {
    my $first_rec = $recordings->{data}[0];
    if ($first_rec->{id}) {
        my $rec_detail = safe('Get recording', sub { $client->recordings->get($first_rec->{id}) });
        if ($rec_detail) {
            print "  Recording: " . ($rec_detail->{duration} // 'N/A')
                . "s, " . ($rec_detail->{format} // 'N/A') . "\n";
        }
    }
}

# --- MFA ---

# 7. Send MFA via SMS
print "\nSending MFA SMS code...\n";
my $request_id;
safe('MFA SMS', sub {
    my $sms_result = $client->mfa->sms(
        to           => '+15551234567',
        from_        => '+15559876543',
        message      => 'Your code is {{code}}',
        token_length => 6,
    );
    $request_id = $sms_result->{id} // $sms_result->{request_id};
    print "  MFA SMS sent: $request_id\n" if $request_id;
});

# 8. Send MFA via voice call
print "\nSending MFA voice code...\n";
safe('MFA call', sub {
    my $voice_result = $client->mfa->call(
        to           => '+15551234567',
        from_        => '+15559876543',
        message      => 'Your verification code is {{code}}',
        token_length => 6,
    );
    print "  MFA call sent: " . ($voice_result->{id} // $voice_result->{request_id} // 'unknown') . "\n";
});

# 9. Verify MFA token
if ($request_id) {
    print "\nVerifying MFA token...\n";
    safe('Verify', sub {
        my $verify = $client->mfa->verify($request_id, token => '123456');
        print "  Verification result: " . (ref $verify ? 'response received' : $verify) . "\n";
    });
}

# 10. Clean up
print "\nCleaning up...\n";
safe('Delete queue', sub { $client->queues->delete($queue_id) }) if $queue_id;
