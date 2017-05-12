#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 32;
use Quantum::ClebschGordan;

sub test_seq {
  my $result = shift;
  my $desc = sprintf "ok w/(%s) [line: %d]",
	join(",", map { defined($_) ? $_ : 'undef' } @_ ),
	(caller())[2],
  ;
  my $aref = eval { [ Quantum::ClebschGordan::__seq(@_) ] };
  return is_deeply( $aref, $result, $desc ) || ($@ && diag("Error: $@"));
}
test_seq( [1,2,3], 1, 3 );
test_seq( [3,2,1], 3, 1 );
test_seq( [1,2,3], 1, 3, 1 );
test_seq( [3,2,1], 3, 1, 1 );
test_seq( [1,1.5,2,2.5,3], 1, 3, 0.5 );
test_seq( [3,2.5,2,1.5,1], 3, 1, 0.5 );

test_seq( [-1,0,1,2,3], -1, 3 );
test_seq( [3,2,1,0,-1], 3, -1 );

test_seq( undef, 1, 3, 0 );
test_seq( [1,2,3], 1, 3, undef );
test_seq( undef, 1, 3, '' );
test_seq( undef, 1, 3, 'foo' );
test_seq( [1,2,3], 1, 3, '1a' );
test_seq( undef, 3, 1, 0 );
test_seq( undef, 3, 1, -1 );
test_seq( undef, 1, 3, -1 );

test_seq( [-1,-2,-3], -1, -3 );
test_seq( [-3,-2,-1], -3, -1 );
test_seq( [-1,-2,-3], -1, -3, 1 );
test_seq( [-3,-2,-1], -3, -1, 1 );

test_seq( [-1,-3], -1, -3, 2 );
test_seq( [-3,-1], -3, -1, 2 );
test_seq( [-1,-3], -1, -3, 2 );
test_seq( [-3,-1], -3, -1, 2 );

test_seq( [-1,-3], -1, -4, 2 );
test_seq( [-4,-2], -4, -1, 2 );
test_seq( [-1,-3], -1, -4, 2 );
test_seq( [-4,-2], -4, -1, 2 );

test_seq( [1,3], 1, 4, 2 );
test_seq( [4,2], 4, 1, 2 );
test_seq( [1,3], 1, 4, 2 );
test_seq( [4,2], 4, 1, 2 );

#eof#

