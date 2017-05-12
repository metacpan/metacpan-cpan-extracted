
use strict;
use warnings;

use Test::More tests => 18;
use Test::MockObject::Extends;

use_ok 'Net::Whois::ARIN';

my $w = Net::Whois::ARIN->new(
    -hostname=> 'whois.arin.net',
    -port    => 43,
    -timeout => 45,
);

my $mock = Test::MockObject::Extends->new( $w );

open AS, "< t/whois/as.txt" or die "Can't open whois/as.txt: $!";
open POC, "< t/whois/poc.txt" or die "Can't open whois/poc.txt: $!";
END { close AS; close POC; }

#  The asn() call will internally call the contacts() routine which
#  both use the query() routine to access requested data.  Let's
#  return the AS record on the first call and the POC record on the
#  subsequent call.
my $call = 0;
$mock->mock("query", sub { $call ++ ? <POC> : <AS> });
$mock->mock("_connect", sub { undef });

isa_ok $w, 'Net::Whois::ARIN';

my $asn = 1234;

can_ok $w, "asn";
my $as = $w->asn($asn);
isa_ok $as, 'Net::Whois::ARIN::AS';

#can_ok $as, "ASNumber";
#can_ok $as, "OrgID";
#can_ok $as, "Address";
#can_ok $as, "City";
#can_ok $as, "StateProv";
#can_ok $as, "PostalCode";
#can_ok $as, "Country";
#can_ok $as, "RegDate";
#can_ok $as, "Updated";
#can_ok $as, "ASName";
#can_ok $as, "ASHandle";
#can_ok $as, "Comment";
#can_ok $as, "contacts";

is $as->ASNumber, $asn;
is $as->OrgID, "SRC";
is $as->Address, "123 North Lincoln Street";
is $as->City, "Rochester";
is $as->StateProv, "NY";
is $as->PostalCode, "14646";
is $as->Country, "US";
is $as->RegDate, "1990-01-01";
is $as->Updated, "2007-02-19";
is $as->ASName, "SOMERANDOM-SRC";
is $as->ASHandle, "AS1234";
is $as->Comment, "";

my @contacts = $as->contacts;
is scalar @contacts, 1, "found 1 contact";
my $c = pop @contacts;
isa_ok $c, "Net::Whois::ARIN::Contact";

exit;

