# $Id: 040-batch.t 2696 2007-10-04 18:17:24Z andy $
use strict;
use warnings;
use Test::More;
use Parallel::Iterator qw( iterate_as_array );

my @spec = (
    { batch    => 97 },
    { batch    => 100 },
    { adaptive => 1 },
    { adaptive => 2 },
    { adaptive => [ 10, 1, 20 ] }
);

plan tests => @spec * 1;

for my $spec ( @spec ) {
    my @in = ( 1 .. 5000 );
    my @want = map { $_ * 2 } @in;

    my @got = iterate_as_array(
        $spec,
        sub {
            my ( $id, $job ) = @_;
            return $job * 2;
        },
        \@in
    );

    is_deeply \@got, \@want, "processed OK";
}

1;
