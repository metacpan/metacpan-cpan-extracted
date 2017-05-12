#!perl
use strict;
use warnings;

# impossible to beat Test::More into submission when fork() is involved
# note: parent uses waitpid to ensure order of output

sub say { print @_, "\n" }

                             say '1..3';
eval 'use Proc::Fork; 1' and say 'ok 1 - use Proc::Fork';

eval do { local $/; <DATA> };
__END__

child  {                     say 'ok 2 - child code runs'  }
parent { waitpid shift, 0;   say 'ok 3 - parent code runs' }

# vim:ft=perl:
