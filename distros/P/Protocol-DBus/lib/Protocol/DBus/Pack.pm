package Protocol::DBus::Pack;

use strict;
use warnings;

use constant CAN_64 => eval { !!pack 'q' };

use constant NUMERIC => {
    y => 'C',   # uint8
    b => 'L',   # boolean (uint32)
    n => 's',   # int16
    q => 'S',   # uint16
    i => 'l',   # int32
    u => 'L',   # uint32
    x => 'q',   # int64
    t => 'Q',   # uint64
    d => 'd',   # double float (?)
    h => 'L',   # unix fd, uint32
};

use constant STRING => {
    s => 'L/a x',
    o => 'L/a x',
    g => 'C/a x',
};

use constant WIDTH => {

    # Accommodate 32-bit Perls:
    (map { $_ => ($_ eq 'x' || $_ eq 't') ? 8 : length pack NUMERIC()->{$_} } keys %{ NUMERIC() }),
    (map { $_ => length pack STRING()->{$_} } keys %{ STRING() }),
};

use constant ALIGNMENT => {
    %{ WIDTH() },
    map { $_ => length pack( substr( STRING()->{$_}, 0, 1 ) ) } keys %{ STRING() },
};

# Increments the 1st arg in-place to align on a boundary of the 2nd arg.
# ex. align( 7, 8 ) will change the $_[0] to be 8.
sub align {
    if ($_[0] % $_[1]) {
        $_[0] += ($_[1] - ($_[0] % $_[1]));
    }
}

sub align_str {
    if (my $mod = length($_[0]) % $_[1]) {
        $_[0] .= "\0" x ($_[1] - $mod);
    }
}

1;
