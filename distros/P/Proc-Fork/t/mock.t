use strict; use warnings;

my $i = 1;
sub ok { print 'not ' x !$_[0], "ok $i - $_[1]\n"; ++$i; $_[0] }
sub diag { s/^/# /mg, print for @_; () }
sub is { ok( $_[0] eq $_[1], $_[2] ) or diag "expected: $_[1]\n", "got:      $_[0]\n" }

our $forkres; BEGIN { *CORE::GLOBAL::fork = sub { $forkres } }

use Proc::Fork;

print "1..12\n";

# basic functionality
{ local $forkres = 1; parent { ok( 1, 'parent code executes' )    };          }
{ local $forkres = 0; child  { ok( 1, 'child code executes'  )    };          }
{                     error  { ok( 1, 'error code executes'  )    };          }
{                     retry  { ok( 1, 'retry code executes'  ); 0 } error {}; }

# pid gets passed in?
{ local $forkres = 42; parent { is( shift, 42, 'pid is passed to parent block' ) }; }

# error catching attempts
eval { parent {} "oops" };
ok( /^Garbage in Proc::Fork setup \(after \w+ clause\)/, 'syntax error catcher fired' ) or diag "$_\n" for "$@";

# test retry logic
my $expect_try;
retry {
	++$expect_try;
	is( $_[ 0 ], $expect_try, "retry attempt $expect_try signalled" );
	return $_[ 0 ] < 5; 
}
error {
	is( $expect_try, 5, 'abort after 5th attempt' );
};
