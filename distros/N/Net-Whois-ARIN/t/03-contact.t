
use strict;
use warnings;

use Test::More tests => 17;
use Test::MockObject::Extends;

use_ok 'Net::Whois::ARIN';

my $w = Net::Whois::ARIN->new(
    -hostname=> 'whois.arin.net',
    -port    => 43,
    -timeout => 45,
);

isa_ok $w, 'Net::Whois::ARIN';

my $mock = Test::MockObject::Extends->new( $w );

open POC, "< t/whois/poc.txt" or die "Can't open whois/poc.txt: $!";
END { close POC }

$mock->mock("query", sub { <POC> });
$mock->mock("_connect", sub { });

my @contact = $w->contact('Some, Contact');
is(scalar @contact, 1, "1 POC record found");
my $contact = pop @contact;

isa_ok $contact, "Net::Whois::ARIN::Contact";

#can_ok $contact, "Type";
#can_ok $contact, "Name";
#can_ok $contact, "Handle";
#can_ok $contact, "Company";
#can_ok $contact, "Address";
#can_ok $contact, "City";
#can_ok $contact, "StateProv";
#can_ok $contact, "PostalCode";
#can_ok $contact, "Country";
#can_ok $contact, "RegDate";
#can_ok $contact, "Updated";
#can_ok $contact, "Phone";
#can_ok $contact, "Email";
#can_ok $contact, "Comment";

is $contact->Name, "Blow, Joe";
is $contact->Handle, "JBLOW-ARIN";
is $contact->Company, "Foobar, Inc.";
is $contact->Address, "18300 Ventura Blvd\nSuite 420";
is $contact->City, "Tarzana";
is $contact->StateProv, "CA";
is $contact->PostalCode, "91356";
is $contact->Country, "US";
is $contact->RegDate, "2004-05-06";
is $contact->Updated, "2004-05-18";
is $contact->Phone, "+1-800-555-2443";
is $contact->Email, "jblow\@foobar.com";
is $contact->Comment, "";

exit;

