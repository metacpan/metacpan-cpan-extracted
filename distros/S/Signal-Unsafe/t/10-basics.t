#! perl

use strict;
use warnings FATAL => 'all';

use Test::More 0.88;
use Signal::Unsafe;
use POSIX 'raise';

my $received;
$Signal::Unsafe{USR1} = sub { $received = [ @_ ] };
raise('USR1');
is(@$received, 3, 'Got 3 arguments');
note(explain($received->[1]));

$Signal::Unsafe::Flags = 0;
$Signal::Unsafe{USR1} = sub { $received = [ @_ ] };
raise('USR1');
is(@$received, 1, 'Got 1 arguments');
note(explain($received));

done_testing();
