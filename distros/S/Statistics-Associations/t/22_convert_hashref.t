use strict;
use Statistics::Associations;
use Test::More tests => 1;

my $asso = Statistics::Associations->new;
while (<DATA>) {
    chomp $_;
    my ( $sex, $like_or_unlike ) = split( /\s/, $_ );
    $asso->make_matrix( $sex, $like_or_unlike, 1 );
}

# convert_hash() test 
{
    my $hash_ref = $asso->convert_hashref;
    my $correct  = {
        'woman' => {
            'unlike' => 5,
            'like'   => 5
        },
        'man' => {
            'unlike' => 4,
            'like'   => 6
        }
    };
    is_deeply( $hash_ref, $correct, "convert_hashref() returns correct hash_ref" );
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