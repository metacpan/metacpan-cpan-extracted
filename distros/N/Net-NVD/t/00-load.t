use v5.20;
use warnings;

use Test::More tests => 4;

use Net::NVD;
pass 'module loaded successfully';

can_ok 'Net::NVD', 'new';

ok my $nvd = Net::NVD->new, 'able to instantiate new object';

can_ok $nvd, qw(new get search);
