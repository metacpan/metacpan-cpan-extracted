# full example, you can paste this into perl:
use Data::Dumper;
use AnyEvent::DNS;
AnyEvent::DNS::resolver->resolve (
   "rmbp.local", "*", my $cv = AnyEvent->condvar);
warn Dumper [$cv->recv];
 
# shortened result:
# [
#   [ 'google.com', 'soa', 'in', 3600, 'ns1.google.com', 'dns-admin.google.com',
#     2008052701, 7200, 1800, 1209600, 300 ],
#   [
#     'google.com', 'txt', 'in', 3600,
#     'v=spf1 include:_netblocks.google.com ~all'
#   ],
#   [ 'google.com', 'a', 'in', 3600, '64.233.187.99' ],
#   [ 'google.com', 'mx', 'in', 3600, 10, 'smtp2.google.com' ],
#   [ 'google.com', 'ns', 'in', 3600, 'ns2.google.com' ],
# ]
 
# resolve a records:
$res->resolve ("ruth.plan9.de", "a", sub { warn Dumper [@_] });
 
# result:
# [
#   [ 'ruth.schmorp.de', 'a', 'in', 86400, '129.13.162.95' ]
# ]
 
# resolve any records, but return only a and aaaa records:
$res->resolve ("test1.laendle", "*",
   accept => ["a", "aaaa"],
   sub {
      warn Dumper [@_];
   }
);
 
# result:
# [
#   [ 'test1.laendle', 'a', 'in', 86400, '10.0.0.255' ],
#   [ 'test1.laendle', 'aaaa', 'in', 60, '3ffe:1900:4545:0002:0240:0000:0000:f7e1' ]
# ]
