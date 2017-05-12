use strict;
use Statistics::Associations;
use Test::More tests => 2;

# contingency() test
{
    my $asso = Statistics::Associations->new;
    while (<DATA>) {
        chomp $_;
        my ( $sex, $like_or_unlike ) = split( /\s/, $_ );
        $asso->make_matrix( $sex, $like_or_unlike, 1 );
    }
    my $matrix      = $asso->matrix;
    my $contingency = $asso->contingency($matrix);
    is( $contingency, '0.1', 'contingency() returns correct data' );
}

# contingency() without make_matrix() test
{
    my $asso = Statistics::Associations->new;
    my $matrix = [
        [ 100, 98, 89,  3,  4,  14,  8],
        [   2, 11,  4, 86, 79,  99, 95],
    ];
    my $contingency = $asso->contingency($matrix);
    is( $contingency, '0.655949911287953', 'contingency() without make_matrix() returns correct data' );
}

__DATA__
man like
man unlike
woman like
man unlike
woman like
man like
woman unlike
woman unlike
man like
man unlike
woman unlike
man like
man like
woman like
woman like
man like
woman unlike
woman like
man unlike
woman unlike