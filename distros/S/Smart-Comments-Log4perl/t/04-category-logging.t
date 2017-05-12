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

### l4p_config: 't/category_logging.config'
### Testing 1...

package Test::Package;
### Testing 2...

package Test::Package2;
### Testing 3...

package TestOther::Package;
### Testing 4...

package main;

# Because the "TELL" on $STDERR doesn't act like a normal TELL, we have artifacts in our output
my $expected = "\n" . q{### Testing 2...} . "\n"
             . "\n" . q{### Testing 3...} . "\n";

is $STDERR, $expected  => 'Logging specific modules works';

