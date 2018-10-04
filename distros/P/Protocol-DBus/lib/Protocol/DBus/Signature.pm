package Protocol::DBus::Signature;

use strict;
use warnings;

# Returns a list of single complete types (SCTs).

sub split {
    my ($sig) = @_;

    my @scts;

    while (length($sig)) {
        my $next_sct_len = Protocol::DBus::Signature::get_sct_length($sig, 0);
        push @scts, substr( $sig, 0, $next_sct_len, q<> );
    }

    return @scts;
}

# Returns the length of the single complete type at $sct_offset.

sub get_sct_length {
    my ($sig, $sct_offset) = @_;

    my $start = $sct_offset;

    my $next = substr($sig, $sct_offset, 1);

    if ($next eq 'a') {

        # “{ }” only happens after “a”
        my $next_2nd = substr($sig, 1 + $sct_offset, 1);
        if ($next_2nd eq '{') {

            # 4 for the “a”, “{”, key type, and “}”.
            # We assume that the signature is well-formed.
            return 4 + get_sct_length($sig, 3 + $sct_offset);
        }

        return 1 + get_sct_length($sig, 1 + $sct_offset);
    }

    if ($next eq '(') {
        while (1) {
            $sct_offset++;

            last if $sct_offset >= length($sig);

            my $next_in_struct = substr($sig, $sct_offset, 1);

            if ($next_in_struct eq '(' || $next_in_struct eq 'a') {
                $sct_offset += get_sct_length($sig, $sct_offset) - 1;
            }
            elsif ($next_in_struct eq ')') {
                last;
            }
        }
    }

    return 1 + ($sct_offset - $start);
}

1;
