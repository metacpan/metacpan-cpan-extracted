use strict;
use warnings;

use Test::Fatal;
use Test::More;

{
    package Foo;

    use Params::Validate qw( validate ARRAYREF );

    sub v1 {
        my %p = validate(
            @_, {
                array => {
                    callbacks => {
                        'checking array contents' => sub {
                            for my $x ( @{ $_[0] } ) {
                                return 0 unless defined $x && !ref $x;
                            }
                            return 1;
                        },
                    }
                }
            }
        );
        return $p{array};
    }
}

{
    for my $size ( 100, 1_000, 100_000 ) {
        my @array = ('x') x $size;
        is_deeply(
            Foo::v1( array => \@array ),
            \@array,
            "validate() handles $size element array correctly"
        );
    }
}

done_testing();
