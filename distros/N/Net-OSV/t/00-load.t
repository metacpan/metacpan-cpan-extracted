use v5.20;
use warnings;

use Test::More tests => 4;

use Net::OSV;
pass 'module loaded successfully';

can_ok 'Net::OSV', 'new';

ok my $osv = Net::OSV->new, 'able to instantiate new object';

can_ok $osv, qw(new query query_batch vuln);
