use warnings;
use strict;

use Test::More;

my $second_proc;

BEGIN {

#    $SIG{__WARN__} = sub { $w = shift; };
    use Script::Singleton glue => 'TEST', warn => 1;
    $second_proc = `$^X t/15-warn.t 2>&1`;
}

like $second_proc, qr/Process.* exited due to exclusive shared memory/, "no warnings spewed if warn not set";


done_testing;
