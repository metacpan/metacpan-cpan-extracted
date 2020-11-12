use strict;
use warnings;

sub func {
    my ($x) = @_;

    my $y = do {
        return 0 unless $x;
        $x + 5;
    };

    return $y + 5;
}

print func(0);
