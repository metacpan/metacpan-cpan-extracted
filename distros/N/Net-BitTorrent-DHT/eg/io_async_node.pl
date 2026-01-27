#!/usr/bin/env perl
use v5.40;
use lib 'lib', '../lib';
use Net::BitTorrent::DHT;
use Net::BitTorrent::DHT::Security;
$|++;
use IO::Async::Loop;
use IO::Async::Handle;
use IO::Async::Timer::Periodic;
#
my $sec  = Net::BitTorrent::DHT::Security->new();
my $id   = $sec->generate_node_id('127.0.0.1');
my $dht  = Net::BitTorrent::DHT->new( node_id_bin => $id, port => 6881, bep42 => 0 );
my $loop = IO::Async::Loop->new;
my %candidates;
my %seen_peers;
my $info_hash = pack( 'H*', '86f635034839f1ebe81ab96bee4ac59f61db9dde' );    # Debian hash

sub add_to_frontier (@nodes) {
    my $new_count = 0;
    for my $n (@nodes) {
        my $hex = unpack( 'H*', $n->{id} );

        # Robust format handling
        my $ip   = $n->{ip}   // ( $n->{data} ? $n->{data}{ip}   : undef );
        my $port = $n->{port} // ( $n->{data} ? $n->{data}{port} : undef );
        next unless $ip;
        unless ( exists $candidates{$hex} ) {
            $candidates{$hex} = { id => $n->{id}, ip => $ip, port => $port, visited => 0 };
            $new_count++;
        }
    }
    return $new_count;
}

# Wrap the DHT socket in an IO::Async handle
my $handle = IO::Async::Handle->new(
    read_handle   => $dht->socket,
    on_read_ready => sub {

        # Loop until socket is empty to avoid event-loop lag
        while (1) {
            my ( $nodes, $peers ) = $dht->handle_incoming();
            last unless @$nodes || @$peers;
            my $new = add_to_frontier(@$nodes);
            for my $p (@$peers) {
                my $key = $p->to_string;
                unless ( $seen_peers{$key}++ ) {
                    say "[ASYNC] !!! FOUND PEER: $key (v" . $p->family . ')';
                }
            }
        }
    },
);
$loop->add($handle);

# Bootstrap timer (more aggressive)
$loop->watch_time(
    after => 0,
    code  => sub {
        say '[ASYNC] Bootstrapping via public routers...';
        $dht->bootstrap();
    }
);

# Periodic search timer
my $timer = IO::Async::Timer::Periodic->new(
    interval => 1,
    on_tick  => sub {

        # Inject current routing table into frontier
        add_to_frontier( $dht->routing_table->find_closest( $info_hash, 50 ) );

        # Prioritize closest unvisited candidates
        my @unvisited = sort { ( $a->{id} ^.$info_hash ) cmp( $b->{id} ^.$info_hash ) } grep { $_->{visited} == 0 && $_->{ip} } values %candidates;
        if (@unvisited) {
            my $batch_size = 12;
            my @batch      = splice( @unvisited, 0, $batch_size );
            for my $c (@batch) {
                $dht->get_peers( $info_hash, $c->{ip}, $c->{port} );
                $c->{visited} = 1;
            }
            say sprintf(
                '[ASYNC] Progress: RT=%d | Frontier=%d | ClosestFound=%s',
                $dht->routing_table->size,
                scalar( keys %candidates ),
                unpack( 'H*', $batch[0]{id} )
            );
        }
        else {
            say '[ASYNC] Frontier exhausted. Re-bootstrapping...';
            $dht->bootstrap();
        }
    }
);
$timer->start;
$loop->add($timer);
say "[ASYNC] DHT Node running on IO::Async. Seeking Debian ISO peers...";
say "[ASYNC] Press Ctrl+C to stop.";
$loop->run;
