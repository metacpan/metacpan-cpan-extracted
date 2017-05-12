# parse ospf6d selfid file, compare results and check error handling

use strict;
use warnings;
use Test::More tests => 1;

use OSPF::LSDB::ospf6d;
my $ospf = OSPF::LSDB::ospf6d->new();

$ospf->{selfid} = [ split(/^/m, <<EOF) ];
Router ID: 10.188.1.10
Uptime: 2d00h39m
SPF delay is 1 sec(s), hold time between two SPFs is 5 sec(s)
Number of external LSA(s) 12
Number of areas attached to this router: 1

Area ID: 10.188.0.0
  Number of interfaces in this area: 3
  Number of fully adjacent neighbors in this area: 2
  SPF algorithm executed 16 time(s)
  Number LSA(s) 4

EOF
$ospf->parse_self();
is_deeply($ospf->{ospf}{self}, {
    areas => [ '10.188.0.0' ],
    routerid => '10.188.1.10',
}, "selfid");
