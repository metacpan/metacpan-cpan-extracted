use strict;
use warnings;
use Test::More;

SKIP: {
  defined(my $pid = fork)
    or skip("Fork failed: $!", 1);

  # parent
  if( $pid ){
    diag "# parent => $$, child => $pid\n";
    ok(1, 'forked');
  }
  # child
  else {
    diag "No warning for child exit...\n";
    exit();
  }

  # Slow down so the child prints first
  #select(undef, undef, undef, 0.25);

  #diag "Calling exit() in parent produces warning:\n";
  #exit();
}

0;
