#!/usr/bin/env perl
use v5.40;
use lib '../lib';
use Net::BitTorrent;
use Net::BitTorrent::Types qw[:all];
use Path::Tiny;
use Time::HiRes qw[time];
$|++;
sub ts () { sprintf '[%4.3fs]', time() - $^T }
my $piece_count      = 0;
my $piece_verified_n = 0;
my $piece_failed_n   = 0;
my $peers_connected  = 0;
my $peers_discovered = 0;
my $last_progress    = 0;
#
my $client = Net::BitTorrent->new( user_agent => 'Net::BitTorrent Example/2.0', upnp_enabled => 1, encryption => ENCRYPTION_PREFERRED, debug => 1 );
#
my ($magnet)     = @ARGV || 'magnet:?xt=urn:btih:481b6e3617be4c88f96cb25e47c9d8272130071e&dn=debian-13.6.0-amd64-netinst.iso';
my $download_dir = path('./downloads');
my $torrent      = $client->add( $magnet, $download_dir );
#
$torrent->on(
    started => sub ($t) {
        print ts() . " EVENT: torrent started\n";
    }
);
$torrent->on(
    stopped => sub ($t) {
        print ts() . " EVENT: torrent stopped\n";
    }
);
$torrent->on(
    peer_discovered => sub ( $t, $peer ) {
        $peers_discovered++;
    }
);
$torrent->on(
    status_update => sub ( $t, $stats ) {
        state $metadata_done = 0;
        if ( !$metadata_done && $t->is_metadata_complete ) {
            say '';
            say ts() . " === METADATA RECEIVED ===";
            say ts() . " Name: " . $t->name;
            say ts() . " Files:";
            say ts() . "   - $_" for $t->files->@*;
            $piece_count = $t->bitfield->size if $t->bitfield;
            say ts() . " Pieces: $piece_count";
            say ts() . " Piece length: " . $t->piece_length(0) . " bytes";
            my $total = 0;
            $total += $t->piece_length($_) for 0 .. $piece_count - 1;
            say ts() . " Total download size: " . sprintf( '%.2f MB', $total / 1048576 );
            $metadata_done = 1;
        }
        my $prog = $t->progress;
        my $have = $t->bitfield ? $t->bitfield->count : 0;
        my $size = $t->bitfield ? $t->bitfield->size  : 0;
        printf ts() . " STATUS: %.2f%%  have=%d/%d  left=%d  down=%d  up=%d  peers=%d  discovered=%d\n", $prog, $have, $size, $stats->{left} // 0,
            $stats->{downloaded} // 0, $stats->{uploaded} // 0, $stats->{peers} // 0, $peers_discovered;
    }
);
$torrent->on(
    piece_verified => sub ( $t, $index ) {
        $piece_verified_n++;
        my $prog = $t->progress;
        printf "\n%s PIECE #%d VERIFIED [%.2f%% ok=%d fail=%d]              \n", ts(), $index, $prog, $piece_verified_n, $piece_failed_n;
    }
);
$torrent->on(
    piece_failed => sub ( $t, $index ) {
        $piece_failed_n++;
        say '';
        print ts() . " PIECE_FAILED #$index [ok=$piece_verified_n fail=$piece_failed_n]\n";
    }
);

# --- All log events from every component ---
$client->on(
    log => sub ( $emitter, @args ) {
        my %extra = @args;
        my $level = $extra{level} // 'info';
        my $msg   = $extra{log}   // '';
        my $class = ref($emitter) // '?';

        # In normal mode, suppress noisy per-block/per-byte debug lines
        if ( $level eq 'debug' && !$ENV{VERBOSE} ) {
            return if $msg =~ /(?:Adding \d+ bytes|Cache miss|write_piece_v1|RECV |SEND |TCP read|Peer received|TCP write|DHT send)/;
        }
        die if chomp $msg;
        printf "%s [%-5s] %-15s %s\n", ts(), uc($level), $class, $msg;
    }
);
#
$client->on(
    peer_connected => sub ( $c, @args ) {
        $peers_connected++;
        print ts() . " PEER_CONNECTED    ($peers_connected total)\n";
    }
);
$client->on(
    peer_disconnected => sub ( $c, @args ) {
        $peers_connected-- if $peers_connected > 0;
        print ts() . " PEER_DISCONNECTED ($peers_connected total)\n";
    }
);
#
say ts() . ' Starting torrent...';
$torrent->start();
say ts() . ' Waiting for seeder discovery and download completion...';
say ts() . ' (Press Ctrl+C to stop)';
say ts() . ' Set VERBOSE=1 for per-block/per-byte detail';
#
my $last_diag   = time();
my $stall_start = undef;
$client->wait(
    sub ($nb) {
        my $now = time();

        # Periodic diagnostics every 30s
        if ( $now - $last_diag >= 30 ) {
            $last_diag = $now;
            my $prog  = $torrent->progress;
            my $delta = $prog - $last_progress;
            my $bf    = $torrent->bitfield;
            my $have  = $bf ? $bf->count : 0;
            my $total = $bf ? $bf->size  : 0;
            my $left  = $total - $have;
            say '';
            say ts() . ' === DIAGNOSTIC ===';
            say ts() . ' Progress:  $prog\%  ($have/$total pieces)';
            say ts() . ' Delta:     $delta\% since last check';
            say ts() . " Verified:  $piece_verified_n  Failed: $piece_failed_n";
            say ts() . " Peers:     $peers_connected connected, $peers_discovered discovered";

            # Block tracking
            my $pending  = 0;
            my $received = 0;
            if ( my $bp = $torrent->blocks_pending ) {
                $pending = scalar( keys %$bp );
            }
            if ( my $br = $torrent->blocks_received ) {
                $received = scalar( keys %$br );
            }
            say ts() . " Blocks:    $pending pending, $received received";
            my $total_inflight = 0;
            for my $p ( $torrent->peer_objects->@* ) {
                $total_inflight += $p->blocks_inflight;
            }
            say ts() . " Inflight:  $total_inflight blocks across " . scalar( $torrent->peer_objects->@* ) . " peers";
            say ts() . ' is_seed:   ' .   ( $torrent->is_seed     ? 'YES' : 'no' );
            say ts() . ' is_finished: ' . ( $torrent->is_finished ? 'YES' : 'no' );

            # Check for stall
            if ( abs($delta) < 0.01 && $have < $total ) {
                if ( !$stall_start ) {
                    $stall_start = $now;
                    say ts() . ' ** STALL DETECTED **';
                }
                else {
                    my $stalled_for = $now - $stall_start;
                    say ts() . " ** STALLED for ${stalled_for}s **";

                    # Peer choking breakdown
                    my ( $choking,    $not_choking )    = ( 0, 0 );
                    my ( $interested, $not_interested ) = ( 0, 0 );
                    for my $p ( $torrent->peer_objects->@* ) {
                        $choking++        if $p->peer_choking;
                        $not_choking++    if !$p->peer_choking;
                        $interested++     if $p->am_interested;
                        $not_interested++ if !$p->am_interested;
                    }
                    say ts() . "   Choking us:     $choking / " .      ( $choking + $not_choking );
                    say ts() . "   We're interested: $interested / " . ( $interested + $not_interested );

                    # Show which pieces are missing (up to 20)
                    if ( $bf && $left > 0 && $left <= 50 ) {
                        say ts() . "   Missing pieces ($left total):";
                        my $shown = 0;
                        for my $i ( 0 .. $total - 1 ) {
                            next if $bf->get($i);
                            say ts() . "     piece #$i";
                            last if ++$shown >= 20;
                        }
                    }
                }
            }
            else {
                $stall_start = undef;
            }
            $last_progress = $prog;
        }
        return $torrent->is_finished;
    }
);
say '';
say ts() . ' === DOWNLOAD COMPLETE ===';
say ts() . ' File: ' . $torrent->files->[0];
say ts() . ' Time: ' . sprintf( '%.1fs', time() - $^T );
say ts() . " Verified: $piece_verified_n  Failed: $piece_failed_n";
#
say ts() . ' Removing torrent from client...';
my $removed = $client->remove_torrent($torrent);
if ($removed) {
    say ts() . ' Torrent removed successfully';
}
else {
    say ts() . ' WARNING: remove_torrent returned undef';
}

# Verify the torrent list is now empty
my $remaining = $client->torrents;
say ts() . ' Remaining torrents: ' . scalar(@$remaining);
$client->shutdown();
