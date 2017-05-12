use strict;
use Statistics::Associations;
use Test::More tests => 2;


# phi() test
{
    my $asso = Statistics::Associations->new;
    while (<DATA>) {
        chomp $_;
        my ( $sex, $like_or_unlike ) = split( /\s/, $_ );
        $asso->make_matrix( $sex, $like_or_unlike, 3 );
    }
	my $matrix = $asso->matrix;
	my $phi = $asso->phi($matrix);
	is($phi, '0.100503781525921','phi() returns correct data');
}

# phi() without make_matrix() test
{
    my $asso = Statistics::Associations->new;
    my $matrix = [
        [ 100, 98, 89,  3,  4,  14,  8],
        [   2, 11,  4, 86, 79,  99, 95],
    ];
    my $phi = $asso->phi($matrix);
    is($phi, '0.869032948250183', 'phi() without make_matrix() returns correct data');
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