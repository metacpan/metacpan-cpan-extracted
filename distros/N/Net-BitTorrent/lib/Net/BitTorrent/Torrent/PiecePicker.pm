use v5.40;
use feature 'class';
no warnings 'experimental::class';
#
use Net::BitTorrent::Emitter;
class Net::BitTorrent::Torrent::PiecePicker v2.1.1 : isa(Net::BitTorrent::Emitter) {
    use Acme::Selection::RarestFirst;
    use Net::BitTorrent::Types qw[:pick];
    field $bitfield : param;
    field $rarest_first = Acme::Selection::RarestFirst->new( size => $bitfield->size );
    field $piece_priorities : param = undef;
    field @piece_priorities;
    field $strategy : param : reader : writer = PICK_RAREST_FIRST;    # SEQUENTIAL, RAREST_FIRST, STREAMING
    field $end_game : reader = 0;
    #
    ADJUST {
        if ($piece_priorities) {
            @piece_priorities = @$piece_priorities;
        }
        else {
            @piece_priorities = (1) x $bitfield->size;
        }
    }
    method update_availability ( $peer_bitfield, $delta ) { $rarest_first->update( $peer_bitfield, $delta ) }

    method set_priority ( $index, $priority ) {
        return if $index < 0 || $index >= $bitfield->size;
        $piece_priorities[$index] = $priority;
    }
    method get_priority     ($index) { $piece_priorities[$index] // 1 }
    method get_availability ($index) { $rarest_first->get_availability($index) }

    method is_interesting ($peer) {
        my $p_bf = $peer->torrent->peer_bitfields->{$peer};
        unless ($p_bf) {
            return 0;
        }
        for ( my $i = 0; $i < $bitfield->size; $i++ ) {
            if ( $p_bf->get($i) && !$bitfield->get($i) && $piece_priorities[$i] > 0 ) {
                return 1;
            }
        }
        return 0;
    }

    method pick_piece ( $peer_bitfield, $blocks_pending ) {
        return undef unless $peer_bitfield;

        # Get all candidates
        my @candidates;
        for ( my $i = 0; $i < $bitfield->size; $i++ ) {
            next if $bitfield->get($i);
            next if !$peer_bitfield->get($i);
            next if $piece_priorities[$i] <= 0;
            push @candidates, $i;
        }
        return undef unless @candidates;

        # Apply Strategy to candidates
        if ( $strategy == PICK_SEQUENTIAL ) {

            # Already sorted by index
        }
        elsif ( $strategy == PICK_STREAMING ) {
            @candidates = sort { ( $piece_priorities[$b] <=> $piece_priorities[$a] ) || ( $a <=> $b ) } @candidates;
        }
        else {
            # RAREST_FIRST
            @candidates = sort { $rarest_first->get_availability($a) <=> $rarest_first->get_availability($b) } @candidates;
        }
        return $candidates[0];
    }

    method pick_block ( $peer, $blocks_pending ) {
        my $peer_bitfield = $peer->torrent->peer_bitfields->{$peer};
        return undef unless $peer_bitfield;

        # Get all candidates
        my @candidates;
        for ( my $i = 0; $i < $bitfield->size; $i++ ) {
            next if $bitfield->get($i);
            next if !$peer_bitfield->get($i);
            next if $piece_priorities[$i] <= 0;
            push @candidates, $i;
        }
        return undef unless @candidates;

        # Apply Strategy to candidates
        if ( $strategy == PICK_SEQUENTIAL ) {

            # Already sorted by index
        }
        elsif ( $strategy == PICK_STREAMING ) {
            @candidates = sort { ( $piece_priorities[$b] <=> $piece_priorities[$a] ) || ( $a <=> $b ) } @candidates;
        }
        else {
            # RAREST_FIRST
            @candidates = sort { $rarest_first->get_availability($a) <=> $rarest_first->get_availability($b) } @candidates;
        }
        for my $piece_idx (@candidates) {
            my $piece_len       = $peer->torrent->piece_length($piece_idx);
            my $offset          = 0;
            my $blocks_received = $peer->torrent->blocks_received;
            while ( $offset < $piece_len ) {
                my $is_pending  = $blocks_pending->{$piece_idx}  && $blocks_pending->{$piece_idx}{$offset};
                my $is_received = $blocks_received->{$piece_idx} && $blocks_received->{$piece_idx}{$offset};
                if ( $end_game || ( !$is_pending && !$is_received ) ) {
                    if ( !$is_received ) {
                        return ( $piece_idx, $offset, 16384 );
                    }
                }
                $offset += 16384;
            }
        }
        return undef;
    }
    method enter_end_game () { $end_game = 1 }
    }
    #
    1;
