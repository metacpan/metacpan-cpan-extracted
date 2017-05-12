use strict;
use warnings;
use Test::More;
use POE;
POE::Kernel->run(); # don't actually initiate the run loop

use FindBin;
use lib "$FindBin::Bin/lib";
use MyTests;

use_ok 'POE::Component::Sequence';

## new()

my $sequence = POE::Component::Sequence->new();
isa_ok $sequence, 'POE::Component::Sequence';

## Ensure that methods are chained that expect to be

is_method_chained $sequence, 'add_callback';
is_method_chained $sequence, 'add_error_callback';
is_method_chained $sequence, 'add_finally_callback';
is_method_chained $sequence, 'add_action';
is_method_chained $sequence, 'add_handler';
is_method_chained $sequence, 'add_delay';
is_method_chained $sequence, 'adjust_delay';
is_method_chained $sequence, 'remove_delay';
is_method_chained $sequence, 'run';

done_testing;
