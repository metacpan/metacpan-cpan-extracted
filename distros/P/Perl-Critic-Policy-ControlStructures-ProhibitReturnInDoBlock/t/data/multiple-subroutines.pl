use strict;
use warnings;

sub func1 {
    my ($x) = @_;

    my $y = do {
        return 0 unless $x;
        $x + 5;
    };

    return $y + 5;
}

sub func2 {
    my ($x) = @_;

    my $y = do {
        return 0 unless $x;
        $x + 5;
    };

    return $y + 5;
}

print func(0);
