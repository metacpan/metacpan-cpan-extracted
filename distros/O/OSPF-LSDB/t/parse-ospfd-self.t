# parse ospfd selfid file, compare results and check error handling

use strict;
use warnings;
use Test::More tests => 1;

use OSPF::LSDB::ospfd;
my $ospf = OSPF::LSDB::ospfd->new();

$ospf->{selfid} = [ split(/^/m, <<EOF) ];
Router ID: 10.188.2.254
Uptime: 2d03h43m
RFC1583 compatibility flag is disabled
SPF delay is 1000 msec(s), hold time between two SPFs is 5000 msec(s)
Number of external LSA(s) 1
Number of areas attached to this router: 1

Area ID: 10.188.0.0
  Number of interfaces in this area: 1
  Number of fully adjacent neighbors in this area: 1
  SPF algorithm executed 4 time(s)
  Number LSA(s) 3

EOF
$ospf->parse_self();
is_deeply($ospf->{ospf}{self}, {
    areas => [ '10.188.0.0' ],
    routerid => '10.188.2.254',
}, "selfid");
