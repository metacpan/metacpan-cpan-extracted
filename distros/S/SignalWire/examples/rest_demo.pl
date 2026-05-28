#!/usr/bin/env perl
# REST Client Demo
#
# Shows how to use the REST client to manage SignalWire resources.
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID
#   SIGNALWIRE_API_TOKEN
#   SIGNALWIRE_SPACE

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
        print "  $label: FAILED - $@\n";
        return undef;
    }
    print "  $label: OK\n";
    return $result;
}

# 1. List phone numbers
print "Listing phone numbers...\n";
my $numbers = safe('List numbers', sub { $client->phone_numbers->list });
if ($numbers) {
    for my $n (@{ $numbers->{data} // [] }[0 .. 4]) {
        last unless $n;
        print "    - " . ($n->{number} // 'unknown') . "\n";
    }
}

# 2. Search available numbers
print "\nSearching available numbers...\n";
safe('Search 512', sub {
    my $avail = $client->phone_numbers->search(area_code => '512', max_results => 3);
    for my $n (@{ $avail->{data} // [] }) {
        print "    - " . ($n->{e164} // $n->{number} // 'unknown') . "\n";
    }
});

# 3. List AI agents
print "\nListing AI agents...\n";
safe('List agents', sub {
    my $agents = $client->fabric->ai_agents->list;
    for my $a (@{ $agents->{data} // [] }) {
        print "    - $a->{id}: " . ($a->{name} // 'unnamed') . "\n";
    }
});

# 4. Datasphere documents
print "\nListing Datasphere documents...\n";
safe('List documents', sub {
    my $docs = $client->datasphere->documents->list;
    for my $d (@{ $docs->{data} // [] }) {
        print "    - $d->{id}: " . ($d->{status} // 'unknown') . "\n";
    }
});

# 5. Video rooms
print "\nListing video rooms...\n";
safe('List rooms', sub {
    my $rooms = $client->video->rooms->list;
    for my $r (@{ $rooms->{data} // [] }) {
        print "    - $r->{id}: " . ($r->{name} // 'unnamed') . "\n";
    }
});

print "\nREST Demo complete.\n";
