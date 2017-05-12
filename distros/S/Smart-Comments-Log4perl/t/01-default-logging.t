#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More 'no_plan';
use Smart::Comments;
use Smart::Comments::Log4perl;

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

### Testing 1...
#### Testing 2...
##### Testing 3...

# Because the "TELL" on $STDERR doesn't act like a normal TELL, we have artifacts in our output
my $expected = "\n" . '### Testing 1...' . "\n" . "\n"
                    . '### Testing 2...' . "\n" . "\n"
                    . '### Testing 3...' . "\n";

is $STDERR, $expected  => 'Standard logging messages work';

