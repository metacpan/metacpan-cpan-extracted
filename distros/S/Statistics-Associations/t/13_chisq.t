use strict;
use Statistics::Associations;
use Test::More tests => 1;

my $asso = Statistics::Associations->new;
while (<DATA>) {
    chomp $_;
    my ( $sex, $like_or_unlike ) = split( /\s/, $_ );
    $asso->make_matrix( $sex, $like_or_unlike, 1 );
}

# chisq() test
{
    my $matrix = $asso->matrix;
    my $chisq  = $asso->chisq($matrix);
    is( $chisq, '0.202020202020202', 'chisq() returns correct data' );
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