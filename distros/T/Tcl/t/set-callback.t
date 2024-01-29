use Tcl;
use strict;
use warnings;

# based on t/tcl-callback.t from the Tkx module.

#$Tcl::TRACE_SHOWCODE=1;
#$Tcl::TRACE_CREATECOMMAND=1;
#$Tcl::TRACE_DELETECOMMAND=1;
#$Tcl::SAVEALLCODES  = 0;

use Test;

my $inter=Tcl->new();

plan tests => 5;

$inter->call('set',"foo", sub {
    ok @_, 2;
    ok "@_", "a b c";
});

ok $inter->call('set',"foo"), qr/^::perl::CODE\(0x/;
$inter->call('eval','[set foo] a {b c}');

$inter->call('set',"foo", [sub {
    ok @_, 4;
    ok "@_", "a b c d e f";
}, "d", "e f"]);
$inter->call('eval','[set foo] a {b c}');

__END__

# this is in the Tkx t/ test program
# but its strange to require something that requires us first.
# so its being skipped in the Tcl t/ series

use Tkx;
$inter->call('set',"foo", [sub {
    ok @_, 6;
    ok "@_", "2 3 a b c d";
}, Tkx::Ev('[expr 1+1]', '[expr 1+2]'), "c", "d"]);
$inter->call('eval','eval [set foo] a b');
