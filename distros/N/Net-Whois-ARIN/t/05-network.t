
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

open NETWORK, "< t/whois/network.txt" or die "Can't open t/whois/network.txt: $!";
open POC, "< t/whois/poc.txt" or die "Can't open t/whois/poc.txt: $!";
END { close NETWORK; close POC; }

my $call = 0;
$mock->mock("query", sub { $call ++ ? <POC> : <NETWORK> });
$mock->mock("_connect", sub { });

my @output = $w->network('127.0.0.0');
ok(@output == 1, 'one result for net 127.0.0.1');
my $network = pop @output;
isa_ok $network, 'Net::Whois::ARIN::Network';

is $network->NetName, "LOOPBACK";
is $network->Address, "4676 Admiralty Way, Suite 330";
is $network->NetType, "IANA Special Use";
is $network->City, "Marina del Rey";
is $network->OrgName, "Internet Assigned Numbers Authority";
is $network->Parent, "";
is $network->OrgID, "IANA";
is $network->PostalCode, "90292-6695";
is $network->NetHandle, "NET-127-0-0-0-1";
is $network->Comment, "Please see RFC 3330 for additional information.";
is $network->RegDate, "";
is $network->StateProv, "CA";
is $network->CIDR, "127.0.0.0/8";
is $network->Updated, "2002-10-14";
is $network->Country, "US";
is $network->NetRange, "127.0.0.0 - 127.255.255.255";

my @contacts = $network->contacts;
is scalar @contacts, 1;

exit;

__END__
