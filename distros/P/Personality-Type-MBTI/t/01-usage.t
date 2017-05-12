#!perl -T

use Test::More tests => 37;

use Personality::Type::MBTI;

my $mbti = Personality::Type::MBTI->new();

# test one type

{
    my $type = $mbti->type(qw( i n f p ));
    is( $type, "infp", "simple test: infp" );
}

{
    my $type = $mbti->type(qw( i n f p e s t j ));
    is( $type, "xxxx", "simple test: xxxx" );
}

{
    my $type = $mbti->type(qw( i n f p 2e 2s 2t 2j ));
    is( $type, "estj", "simple test: weighted values" );
}

{
    my $type = $mbti->type(qw( i i n n f f p p 2e 2s 2t 2j ));
    is( $type, "xxxx", "simple test: weighted values" );
}

{
    my $type = $mbti->type(qw( -1i -1n -1f -1p ));
    is( $type, "estj", "simple test: negative values" );
}



# test all the types

for my $w (qw/e i/) {
    for my $x (qw/s n/) {
        for my $y (qw/t f/) {
            for my $z (qw/p j/) {
                my @test = ( $w, $x, $y, $z ) x 4;
                my $test = join( ", ", @test );
                my $type = $mbti->type(@test);
                is( $type, "$w$x$y$z", "($test) is $w$x$y$z" );
            }
        }
    }
}

# repeat test, adding 3 random letters and
# shuffling the array
# (it should still get the same results)

for my $w (qw/e i/) {
    for my $x (qw/s n/) {
        for my $y (qw/t f/) {
            for my $z (qw/p j/) {
                my @test = ( $w, $x, $y, $z ) x 4;
                push @test, _rand_letter() for ( 1 .. 3 );
                _shuffle( \@test );
                my $test = join( ", ", @test );
                my $type = $mbti->type(@test);
                is( $type, "$w$x$y$z", "($test) is $w$x$y$z" );
            }
        }
    }
}

sub _shuffle {
    my $array_ref = shift;
    my $i;
    for ( $i = @$array_ref ; --$i ; ) {
        my $j = int rand( $i + 1 );
        next if $i == $j;
        @$array_ref[ $i, $j ] = @$array_ref[ $j, $i ];
    }
}

sub _rand_letter {
    my @possible = qw( e i s n f t p j );
    return $possible[ rand(@possible) ];
}
