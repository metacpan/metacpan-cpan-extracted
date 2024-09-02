#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    use Nice::Try;
};

use strict;
use warnings;
our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;

# Credits to Clay Fouts for the tests
# This is to address the bug #7

my $rv = 0;
sub foo1
{
    try {
        return ["hello"];
    } catch {
        warn 'Caught!';
    }
    $rv++;
}

sub foo2
{
    try {
        diag( 'Trying...' ) if( $DEBUG );
        $rv++;
    } catch($e) {
        warn 'Caught!';
    }
    return ["bye"];
}

local $@;
diag( "Calling coerced foo1()" ) if( $DEBUG );
my @foos = eval{ @{foo1()}; };

ok( !$@, "no error" );
diag( "Oops, error: $@" ) if( $@ );
is( $rv, 0, "returned properly" );
is( $foos[0], "hello", "returned an array" );

$rv = 0;
diag( 'Calling bare foo2()' ) if( $DEBUG );
foo2();

$rv = 0;
diag( "Calling coerced foo2()" ) if( $DEBUG );
@foos = eval{ @{foo2()} };
ok( !$@, "no error" );
diag( "Oops, error: $@" ) if( $@ );
is( $rv, 1, "returned properly" );
is( $foos[0], "bye", "returned an array" );

done_testing();

__END__

