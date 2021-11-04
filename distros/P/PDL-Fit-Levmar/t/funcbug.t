use strict;
use warnings;
use Test::More;
use PDL::Fit::Levmar::Func;

# gjl dec 2012
# Supplied by Edward Baudrez to trigger a bug.
# The funcion f gets a single arg. But after the call
# to levmar func, @_ is replaced with the first line
# of the generated C file. I still don't understand where
# the stack corruption comes from, but changed a line
# with comments in the function clean_files in func.pd

sub f
{
        my $model = levmar_func( FUNC => "function\n x = p0 + p1*t;" );
        is_deeply \@_, [ 3 ], "f() doesn't modify \@_";
}

my $array = [ 3 ];
f( $_ ) for @$array;
f( $_ ) for 3;

done_testing;
