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

### l4p_config: 't/warning_only.config'
### l4p_warn:  'Testing 1...'
### l4p_debug: 'Testing 2...'
### l4p_info:  'Testing 3...'

### Testing 4...
### l4p_level: 'info'
### Testing 5...
### l4p_level: 'warn'
### Testing 6...

# Because the "TELL" on $STDERR doesn't act like a normal TELL, we have artifacts in our output
my $expected = "\n" . q{###  'Testing 1...'} . "\n"
             . "\n" . q{### Testing 6...}    . "\n";

is $STDERR, $expected  => 'Logging levels work';

