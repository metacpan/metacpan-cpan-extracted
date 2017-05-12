use strict;
use Test::More;
END { done_testing }
use Search::Binary;

sub make_reader {
    my ( $array ) = @_;
    my $last_pos;
    return sub {
        my (undef, $val, $pos) = @_;
        $pos = $last_pos + 1 unless defined $pos;
        $last_pos = $pos;
        return ($val <=> $array->[$pos]{a}, $pos);
    }
}

my @x = ({a => 1}, {a => 4}, {a => 5}, {a => 9}, {a => 12});

foreach my $x (15, 15)  {
    my $next_pos = binary_search(0, $#x, $x, make_reader([ @x ]), undef);
    is $next_pos, 5;
}
