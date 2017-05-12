use strict;
use Statistics::Associations;
use Test::More tests => 1;

my $asso = Statistics::Associations->new;
while (<DATA>) {
    chomp $_;
    my ( $sex, $like_or_unlike ) = split( /\s/, $_ );
    $asso->make_matrix( $sex, $like_or_unlike, 1 );
}

# object test 
{
    my $correct = bless(
        {
            'col_count' => 2,
            'col_label' => [ 'like', 'unlike' ],
            'col'       => {
                'unlike' => 2,
                'like'   => 1
            },
            'row' => {
                'woman' => 2,
                'man'   => 1
            },
            'row_count' => 2,
            'matrix'    => [ [ 6, 4 ], [ 5, 5 ] ],
            'row_label' => [ 'man', 'woman' ]
        },
        'Statistics::Associations'
    );
    is_deeply( $asso, $correct, "make_matric() makes correct object" );
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