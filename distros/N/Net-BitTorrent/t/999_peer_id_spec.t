use v5.40;
use lib 'lib', '../lib';
use Net::BitTorrent;
use Test2::V1;
T2->subtest(
    'Peer ID Specification',
    sub {
        my $client = Net::BitTorrent->new();
        my $id     = $client->node_id;
        T2->is( length($id), 20, 'Peer ID is 20 bytes' );
        T2->like( $id, qr/^-NB\d{3}[SU]-/, 'Peer ID follows Azureus-style header specification' );

        # -NB (3) + digits (3) + stability (1) + hyphen (1) = 8 characters
        my $signature = substr( $id, 8 );
        T2->is( length($signature), 12, 'Signature is 12 characters' );

        # The spec says 12 characters. Our implementation uses 7 random + 'Sanko'
        T2->like( $signature, qr/^[A-Za-z0-9\-\._~]{7}.{5}$/, 'Signature matches [7 random chars][5 more chars]' );
        T2->note("Generated Peer ID: $id");
    }
);
T2->done_testing;
