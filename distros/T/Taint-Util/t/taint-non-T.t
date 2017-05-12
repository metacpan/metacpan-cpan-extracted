=pod

Try tainting when not under B<-T>.

=cut

use strict;

use Test::More tests => 2;
use Taint::Util;

my $s = 420;
ok !tainted($s) => "fresh scalar untainted";

# taint
taint($s); ok !tainted($s) => "did not taint scalar when not under taint mode";


