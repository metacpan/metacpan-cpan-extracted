use v5.40;
use lib 'lib', '../lib';
use Net::BitTorrent::DHT;
use Net::BitTorrent::DHT::Security;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bdecode bencode];
use Digest::SHA                               qw[sha1];
use IO::Select;
$|++;

# Revised BEP 44 Demo: Two nodes in one process using IO::Select
my $sec    = Net::BitTorrent::DHT::Security->new();
my $node   = Net::BitTorrent::DHT->new( node_id_bin => $sec->generate_node_id('127.0.0.1'), port => 6881, address => '127.0.0.1' );
my $client = Net::BitTorrent::DHT->new( node_id_bin => $sec->generate_node_id('127.0.0.1'), port => 6882, address => '127.0.0.1' );
my $sel    = IO::Select->new( $node->socket, $client->socket );

sub pump {
    my $timeout = shift // 0.1;
    my $end     = time + $timeout;
    my @client_results;
    while ( time <= $end ) {
        if ( my @ready = $sel->can_read(0.01) ) {
            for my $fh (@ready) {
                if ( $fh == $node->socket ) {
                    $node->handle_incoming();
                }
                elsif ( $fh == $client->socket ) {
                    my ( $nodes, $peers, $data ) = $client->handle_incoming();
                    push @client_results, $data if $data;
                }
            }
        }
    }
    return @client_results;
}
say '[INFO] Storage Node on 6881, Client Node on 6882';

# Step 1: Get Token
say '[DEMO] Step 1: Requesting token...';
$client->get_peers( sha1('dummy'), '127.0.0.1', 6881 );
my ($res) = pump(1.0);
my $token = $res->{token} or die '[ERROR] No token received';
say '[INFO] Token: ' . unpack( 'H*', $token );

# Step 2: Immutable Put
my $val    = 'BEP 44 is cool';
my $target = sha1($val);
say '[DEMO] Step 2: Storing immutable data...';
$client->put_remote( { v => $val, token => $token }, '127.0.0.1', 6881 );
pump(0.2);    # Let storage node process it

# Step 3: Immutable Get
say '[DEMO] Step 3: Retrieving immutable data...';
$client->get_remote( $target, '127.0.0.1', 6881 );
($res) = pump(1.0);
if ( $res && $res->{v} eq $val ) {
    say '[SUCCESS] Retrieved: ' . $res->{v};
}
else {
    say '[ERROR] Retrieval failed';
}

# Step 4: Mutable (if possible)
if ( eval { require Crypt::PK::Ed25519; 1 } ) {
    say '[DEMO] Step 4: Mutable data...';
    my $pk       = Crypt::PK::Ed25519->new()->generate_key();
    my $pub      = $pk->export_key_raw('public');
    my $m_val    = 'Version 1';
    my $seq      = 1;
    my $to_sign  = 'seqi' . $seq . 'ev' . length($m_val) . ':' . $m_val;
    my $sig      = $pk->sign_message($to_sign);
    my $m_target = sha1($pub);
    $client->put_remote( { v => $m_val, k => $pub, seq => $seq, sig => $sig, token => $token }, '127.0.0.1', 6881 );
    pump(0.5);
    $client->get_remote( $m_target, '127.0.0.1', 6881 );
    ($res) = pump(1.0);

    if ( $res && $res->{v} eq $m_val ) {
        say sprintf '[SUCCESS] Retrieved mutable: "%s" (seq: %s)', $res->{v}, $res->{seq};
    }
    else {
        say '[ERROR] Mutable retrieval failed';
    }
}
say '[INFO] Demo complete.';
