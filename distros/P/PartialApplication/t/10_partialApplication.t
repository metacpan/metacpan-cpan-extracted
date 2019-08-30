use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

use PartialApplication qw( partiallyApply partiallyApplyRight partiallyApplyN );

throws_ok { partiallyApply() } qr/first parameter needs to be a function ref/, "partiallyApply should thorw an error if we don't give it a function ref as the first parameter";
throws_ok { partiallyApply( 'asdf' ) } qr/first parameter needs to be a function ref/, "partiallyApply should thorw an error if we don't give it a function ref as the first parameter";

throws_ok { partiallyApplyRight() } qr/first parameter needs to be a function ref/, "partiallyApply should thorw an error if we don't give it a function ref as the first parameter";
throws_ok { partiallyApplyRight( 'asdf' ) } qr/first parameter needs to be a function ref/, "partiallyApply should thorw an error if we don't give it a function ref as the first parameter";

throws_ok { partiallyApplyN() } qr/first parameter needs to be a function ref/, "partiallyApply should thorw an error if we don't give it a function ref as the first parameter";
throws_ok { partiallyApplyN( 'asdf' ) } qr/first parameter needs to be a function ref/, "partiallyApply should thorw an error if we don't give it a function ref as the first parameter";


sub testSub {
    return @_;
}


my $testSub1 = partiallyApply( \&testSub, 1, 2, 3 );

cmp_deeply( [ $testSub1->() ], [1, 2, 3], "Partially applied subs called without any params should still get the partially applied parameters");
cmp_deeply( [ $testSub1->(4, 5, 6) ], [1, 2, 3, 4, 5, 6], "Partially applied subs should get the parameters in the correct order (partially applied params first)");

my $testSub2 = partiallyApplyRight( \&testSub, 1, 2, 3 );

cmp_deeply( [ $testSub2->() ], [1, 2, 3], "Righthand partially applied subs called without any params should still get the partially applied parameters");
cmp_deeply( [ $testSub2->(4, 5, 6) ], [4, 5, 6, 1, 2, 3], "Righthand partially applied subs should get the parameters in the correct order (partially applied params last)");

my $testSub3 = partiallyApplyN( \&testSub, [1, 0, 1, 0, 1], 1, 2, 3 );

cmp_deeply( [ $testSub3->() ], [1, undef, 2, undef, 3], "ParitallyAppliedN'd subs should use undef when there isn't a suitable parameter" );
cmp_deeply( [ $testSub3->(4, 5, 6) ], [1, 4, 2, 5, 3, 6], "PartiallyAppliedN'd subs should apply the parameters in the order specified by the bitmap" );


{
    package TestClass;

    sub new {
        my $x = {
            append => [],
        };

        return bless $x;
    }

    sub append {
        my ( $self, @appendVars ) = @_;
        $self->{append} = [ @appendVars ];
    }

    sub testMethod {
        my ( $self, @params ) = @_;

        return ( @params, @{ $self->{append} } );
    }

    1;
}

my $testObject1 = TestClass->new();
my $testObject2 = TestClass->new();

my $testMethod1 = partiallyApply( \&TestClass::testMethod, $testObject1, 1, 2, 3 );

cmp_deeply( [ $testMethod1->() ], [ 1, 2, 3 ], "Partially applied methods called without any params should still get the partially applied parameters" );
cmp_deeply( [ $testMethod1->(4, 5, 6) ], [ 1, 2, 3, 4, 5, 6 ], "Partially applied methods called with parameters should get the partially applied parameters first" );

$testObject1->append( 7, 8, 9 );
$testObject2->append( 'a', 'b', 'c' );

my $testMethod2 = partiallyApplyN( \&TestClass::testMethod, [ 0, 1, 1, 1 ], 1, 2, 3 );

cmp_deeply( [ $testMethod2->($testObject1) ], [ 1, 2, 3, 7, 8, 9 ], "partialApplyN'd methods should fill any gaps in the bitmap with parameters from the call" );
cmp_deeply( [ $testMethod2->($testObject2) ], [ 1, 2, 3, 'a', 'b', 'c' ], "partialApplyN'd methods should apply the parameters as specified by the bitmap" );


done_testing();
