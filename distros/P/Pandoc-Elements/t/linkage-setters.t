use strict;
use warnings;
use Test::More 0.96;    # for subtests

use Pandoc::Elements qw[ attributes Str Link Image ];

my @tests = ( [ Link => \&Link ], [Image => \&Image], );

for my $test ( @tests ) {
    my ( $type, $constr ) = @$test;
    subtest $type => sub {
        my $e = $constr->( attributes {}, [ Str $type], [] );
        ok( ( can_ok( $e, 'name' ) and $e->name eq $type ), 'name' );
        for my $method ( qw[ url title ] ) {
            can_ok $e, $method;
            is $e->$method, "", "$method unset";
            is $e->$method( $method ), $method, "set $method";
            is $e->$method, $method, "$method set";
        }
    };
}

done_testing;
