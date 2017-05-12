
use strict;
use warnings;

use Test::More tests => 21;
use Test::MockObject::Extends;

use_ok 'Net::Whois::ARIN';

my $w = Net::Whois::ARIN->new(
    -hostname=> 'whois.arin.net',
    -port    => 43,
    -timeout => 45,
);

isa_ok $w, 'Net::Whois::ARIN';

my $mock = Test::MockObject::Extends->new( $w );

open CUSTOMER, "< t/whois/customer.txt" or die "Can't open t/whois/customer.txt: $!";
open POC, "< t/whois/poc.txt" or die "Can't open t/whois/poc.txt: $!";
END { close CUSTOMER; close POC; }

my $call = 0;
$mock->mock("query", sub { $call ++ ? <POC> : <CUSTOMER> });
$mock->mock("_connect", sub { });

my @customer = $w->customer('Some Company');
is scalar @customer, 1;
my $customer = pop @customer;
isa_ok $customer, 'Net::Whois::ARIN::Customer';

is $customer->CustName, "Some Company";
is $customer->Address, "1234 State Street";
is $customer->City, "North Andover";
is $customer->StateProv, "MA";
is $customer->PostalCode, "01845";
is $customer->Country, "US";
is $customer->RegDate, "2003-05-07";
is $customer->Updated, "2003-05-07";

is $customer->NetRange, "10.0.0.0 - 10.0.0.255";
is $customer->CIDR, "10.0.0.0/24";
is $customer->NetName, "SOME-COMPANY-1";
is $customer->NetHandle, "NET-10-0-0-0-24";
is $customer->Parent, "NET-10-0-0-0-8";
is $customer->NetType, "Reassigned";
is $customer->Comment, "";

my @contacts = $customer->contacts();
is scalar @contacts, 1;
my $contact = pop @contacts;
isa_ok $contact, "Net::Whois::ARIN::Contact";

exit;

