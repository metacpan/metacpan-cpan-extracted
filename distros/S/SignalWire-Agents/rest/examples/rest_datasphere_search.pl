#!/usr/bin/env perl
# Example: Upload a document to Datasphere and run a semantic search.
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID   - your SignalWire project ID
#   SIGNALWIRE_API_TOKEN    - your SignalWire API token
#   SIGNALWIRE_SPACE        - your SignalWire space

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents::REST::SignalWireClient;

my $client = SignalWire::Agents::REST::SignalWireClient->new(
    project => $ENV{SIGNALWIRE_PROJECT_ID} // die("Set SIGNALWIRE_PROJECT_ID\n"),
    token   => $ENV{SIGNALWIRE_API_TOKEN}  // die("Set SIGNALWIRE_API_TOKEN\n"),
    host    => $ENV{SIGNALWIRE_SPACE}      // die("Set SIGNALWIRE_SPACE\n"),
);

# 1. Upload a document
print "Uploading document to Datasphere...\n";
my $doc = $client->datasphere->documents->create(
    url  => 'https://filesamples.com/samples/document/txt/sample3.txt',
    tags => ['support', 'demo'],
);
my $doc_id = $doc->{id};
print "  Document created: $doc_id (status: " . ($doc->{status} // 'unknown') . ")\n";

# 2. Wait for vectorization to complete
print "\nWaiting for document to be vectorized...\n";
for my $i (1 .. 30) {
    sleep 2;
    my $doc_status = $client->datasphere->documents->get($doc_id);
    my $status = $doc_status->{status} // 'unknown';
    print "  Poll $i: status=$status\n";

    if ($status eq 'completed') {
        print "  Vectorized! Chunks: " . ($doc_status->{number_of_chunks} // 0) . "\n";
        last;
    }
    if ($status eq 'error' || $status eq 'failed') {
        print "  Document processing failed: $status\n";
        $client->datasphere->documents->delete($doc_id);
        exit 1;
    }

    if ($i == 30) {
        print "  Timed out waiting for vectorization.\n";
        $client->datasphere->documents->delete($doc_id);
        exit 1;
    }
}

# 3. List chunks
print "\nListing chunks for document $doc_id...\n";
my $chunks = $client->datasphere->documents->list_chunks($doc_id);
my @chunk_list = @{ $chunks->{data} // [] };
for my $chunk (@chunk_list[0 .. ($#chunk_list < 4 ? $#chunk_list : 4)]) {
    my $content = $chunk->{content} // '';
    $content = substr($content, 0, 80) . '...' if length($content) > 80;
    print "  - Chunk $chunk->{id}: $content\n";
}

# 4. Semantic search
print "\nSearching Datasphere...\n";
my $results = $client->datasphere->documents->search(
    query_string => 'lorem ipsum dolor sit amet',
    count        => 3,
);
for my $chunk (@{ $results->{chunks} // [] }) {
    my $text = $chunk->{text} // '';
    $text = substr($text, 0, 100) . '...' if length($text) > 100;
    print "  - $text\n";
}

# 5. Clean up
print "\nDeleting document $doc_id...\n";
$client->datasphere->documents->delete($doc_id);
print "  Deleted.\n";
