use strict;
use warnings;

use Test2::V0;

use Parallel::Subs;

subtest 'callbacks accumulate results' => sub {
    my $sum = 0;

    my $p = Parallel::Subs->new();
    $p->add(
        sub { return { number => 1 } },
        sub {
            my $result = shift;
            $sum += $result->{number};
        }
    )
    ->add( _multiply( 1, 2 ),  sub { $sum += shift } )
    ->add( _multiply( 3, 4 ),  sub { $sum += shift } )
    ->add( _multiply( 5, 6 ),  sub { $sum += shift } )
    ->add( _multiply( 7, 8 ),  sub { $sum += shift } )
    ->add( _multiply( 9, 10 ), sub { $sum += shift } );

    $p->wait_for_all();

    # 1 + (1*2) + (3*4) + (5*6) + (7*8) + (9*10) = 1 + 2 + 12 + 30 + 56 + 90 = 191
    is $sum, 191, "sum of all callback results";
};

done_testing;

sub _multiply {
    my ( $a, $b ) = @_;
    return sub { return $a * $b };
}
