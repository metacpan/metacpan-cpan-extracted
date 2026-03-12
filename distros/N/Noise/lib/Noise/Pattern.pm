use v5.42.0;
use feature 'class';
no warnings 'experimental::class';
#
class Noise::Pattern v0.0.1 {

    # Noise handshake patterns (rundamental + deferred + one-way)
    # https://noiseprotocol.org/noise.html#handshake-patterns
    my %PATTERNS = (

        # Fundamental Interactive Patterns
        NN => { pre_msg => [ [], [] ],       msg_seq => [ ['e'], [ 'e', 'ee' ] ] },
        NK => { pre_msg => [ [], ['s'] ],    msg_seq => [ [ 'e', 'es' ], [ 'e', 'ee' ] ] },
        NX => { pre_msg => [ [], [] ],       msg_seq => [ ['e'], [ 'e', 'ee', 's', 'es' ] ] },
        XN => { pre_msg => [ [], [] ],       msg_seq => [ ['e'], [ 'e', 'ee' ], [ 's', 'se' ] ] },
        XK => { pre_msg => [ [], ['s'] ],    msg_seq => [ [ 'e', 'es' ], [ 'e', 'ee' ], [ 's', 'se' ] ] },
        XX => { pre_msg => [ [], [] ],       msg_seq => [ ['e'], [ 'e', 'ee', 's', 'es' ], [ 's', 'se' ] ] },
        KN => { pre_msg => [ ['s'], [] ],    msg_seq => [ ['e'], [ 'e', 'ee', 'se' ] ] },
        KK => { pre_msg => [ ['s'], ['s'] ], msg_seq => [ [ 'e', 'es', 'ss' ], [ 'e', 'ee', 'se' ] ] },
        KX => { pre_msg => [ ['s'], [] ],    msg_seq => [ ['e'], [ 'e', 'ee', 'se', 's', 'es' ] ] },
        IN => { pre_msg => [ [], [] ],       msg_seq => [ [ 'e', 's' ], [ 'e', 'ee', 'se' ] ] },
        IK => { pre_msg => [ [], ['s'] ],    msg_seq => [ [ 'e', 'es', 's', 'ss' ], [ 'e', 'ee', 'se', 'es' ] ] },
        IX => { pre_msg => [ [], [] ],       msg_seq => [ [ 'e', 's' ], [ 'e', 'ee', 'se', 's', 'es' ] ] },

        # One-way Handshake Patterns
        N => { pre_msg => [ [], ['s'] ],    msg_seq => [ [ 'e', 'es' ] ] },
        K => { pre_msg => [ ['s'], ['s'] ], msg_seq => [ [ 'e', 'es', 'ss' ] ] },
        X => { pre_msg => [ [], ['s'] ],    msg_seq => [ [ 'e', 'es', 's', 'ss' ] ] },

        # Deferred Interactive Patterns
        NK1  => { pre_msg => [ [], ['s'] ],    msg_seq => [ ['e'], [ 'e', 'ee', 'es' ] ] },
        NX1  => { pre_msg => [ [], [] ],       msg_seq => [ ['e'], [ 'e', 'ee', 's' ], ['es'] ] },
        X1N  => { pre_msg => [ [], [] ],       msg_seq => [ ['e'], [ 'e', 'ee' ], [ 's', 'se' ] ] },
        X1K  => { pre_msg => [ [], ['s'] ],    msg_seq => [ ['e'], [ 'e', 'ee' ], [ 's', 'se', 'es' ] ] },
        XK1  => { pre_msg => [ [], ['s'] ],    msg_seq => [ [ 'e', 'es' ], [ 'e', 'ee', 's' ], ['se'] ] },
        X1K1 => { pre_msg => [ [], ['s'] ],    msg_seq => [ ['e'], [ 'e', 'ee', 's' ], [ 'es', 'se' ] ] },
        X1X  => { pre_msg => [ [], [] ],       msg_seq => [ ['e'], [ 'e', 'ee', 's', 'es' ], [ 's', 'se' ] ] },
        XX1  => { pre_msg => [ [], [] ],       msg_seq => [ ['e'], [ 'e', 'ee', 's' ], [ 'es', 's', 'se' ] ] },
        X1X1 => { pre_msg => [ [], [] ],       msg_seq => [ ['e'], [ 'e', 'ee', 's' ], [ 'es', 's', 'se' ] ] },
        K1N  => { pre_msg => [ ['s'], [] ],    msg_seq => [ ['e'], [ 'e', 'ee' ], ['se'] ] },
        K1K  => { pre_msg => [ ['s'], ['s'] ], msg_seq => [ ['e'], [ 'e', 'ee', 'es' ], ['se'] ] },
        KK1  => { pre_msg => [ ['s'], ['s'] ], msg_seq => [ [ 'e', 'es' ], [ 'e', 'ee', 'se', 'es' ] ] },
        K1K1 => { pre_msg => [ ['s'], ['s'] ], msg_seq => [ ['e'], [ 'e', 'ee', 'es' ], ['se'] ] },
        K1X  => { pre_msg => [ ['s'], [] ],    msg_seq => [ ['e'], [ 'e', 'ee', 'se' ], [ 's', 'es' ] ] },
        K1X1 => { pre_msg => [ ['s'], [] ],    msg_seq => [ ['e'], [ 'e', 'ee', 'se', 's' ], ['es'] ] },
        KX1  => { pre_msg => [ ['s'], [] ],    msg_seq => [ ['e'], [ 'e', 'ee', 'se', 's' ], ['es'] ] },

        # Patterns used in tests (some might be non-standard or specific variants)
        I1N  => { pre_msg => [ [], [] ],    msg_seq => [ [ 'e', 's' ], [ 'e', 'ee' ], ['se'] ] },
        I1K  => { pre_msg => [ [], ['s'] ], msg_seq => [ [ 'e', 'es', 's' ], [ 'e', 'ee' ], ['se'] ] },
        IK1  => { pre_msg => [ [], ['s'] ], msg_seq => [ [ 'e', 'es', 's' ], [ 'e', 'ee' ], [ 'se', 'ss' ] ] },
        I1K1 => { pre_msg => [ [], ['s'] ], msg_seq => [ [ 'e', 's' ], [ 'e', 'ee' ], [ 'se', 'es' ] ] },
        I1X  => { pre_msg => [ [], [] ],    msg_seq => [ [ 'e', 's' ], [ 'e', 'ee', 's', 'es' ], ['se'] ] },
        IX1  => { pre_msg => [ [], [] ],    msg_seq => [ [ 'e', 's' ], [ 'e', 'ee', 'se', 's' ], ['es'] ] },
        I1X1 => { pre_msg => [ [], [] ],    msg_seq => [ [ 'e', 's' ], [ 'e', 'ee', 's' ], [ 'se', 'es' ] ] },
    );
    #
    field $name    : reader : param;
    field $pre_msg : reader;
    field $msg_seq : reader;
    field $has_psk : reader = 0;
    #
    ADJUST {
        my $base_name = $name;
        my @psk_modifiers;
        unshift @psk_modifiers, $1 while $base_name =~ s/[+]?(psk\d+)$//;
        $has_psk = scalar @psk_modifiers > 0;

        # Lookup base pattern
        my $p = $PATTERNS{$base_name} or die 'Unknown pattern: ' . $base_name;

        # Deep copy sequences to avoid modifying shared state
        $pre_msg = [ [ @{ $p->{pre_msg}[0] } ], [ @{ $p->{pre_msg}[1] } ] ];
        $msg_seq = [ map { [@$_] } @{ $p->{msg_seq} } ];
        for my $mod (@psk_modifiers) {
            my ($idx) = $mod =~ /(\d+)/;
            if ( $idx == 0 ) {
                unshift $msg_seq->[0]->@*, 'psk';
            }
            else {
                # psks are added after the (idx)-th message
                # noise-c vectors often use multiple PSKs
                push $msg_seq->[ $idx - 1 ]->@*, 'psk' if $idx <= scalar @$msg_seq;
            }
        }
    }
};
#
1;
