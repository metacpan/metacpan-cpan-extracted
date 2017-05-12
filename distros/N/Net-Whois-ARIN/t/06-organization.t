
use strict;
use warnings;

use Test::More tests => 21;
use Test::MockObject::Extends;
use Fcntl "SEEK_SET";

use_ok 'Net::Whois::ARIN';

my $w = Net::Whois::ARIN->new(
    -hostname=> 'whois.arin.net',
    -port    => 43,
    -timeout => 45,
);

isa_ok $w, 'Net::Whois::ARIN';

# prepare data for stubbing out whois query output
my $ORG_FILE = "t/whois/organization.txt";
my $POC_FILE = "t/whois/poc.txt";
open ORG, "< $ORG_FILE" 
    or die "Can't open $ORG_FILE: $!";
open POC, "< $POC_FILE" 
    or die "Can't open  $POC_FILE: $!";
END { close ORG; close POC; }

#  stub out Net::Whois::ARIN::query so that we don't
#  have to make a network connection in order to run tests
my $mock = Test::MockObject::Extends->new( $w );
{  
    my $call = 0;
    $mock->mock("query", sub { 
        if ($call ++) {
            my @data = <POC>;
            # reset the poc filehandle so that we can read it multiple times
            warn  "Seek on filehandle associated with $POC_FILE failed: $!\n"
                unless seek(POC, 0, SEEK_SET);
            return @data;
        } else {
            return <ORG>;
        }
    });
}
$mock->mock("_connect", sub { });

my @organization = $w->organization('SRC');
is scalar @organization, 1;
my $org = pop @organization;
isa_ok $org, 'Net::Whois::ARIN::Organization';

is $org->OrgID, 'SRC';
is $org->ReferralServer, 'rwhois://whois.somecompany.com:4321';
is $org->PostalCode, '98662';
is $org->Address, '4455 NW 97th Street';
is $org->City, 'Vancouver';
is $org->Comment, '';
is $org->RegDate, '2006-07-24';
is $org->StateProv, 'WA';
is $org->OrgName, 'Some Random Company';
is $org->Updated, '2006-07-24';
is $org->Country, 'US';
is $org->Parent, undef;

my @contact = $org->contacts;
is scalar @contact, 3;
isa_ok $contact[0], "Net::Whois::ARIN::Contact";

is $contact[0]->Type, 'Abuse';
is $contact[1]->Type, 'Admin';
is $contact[2]->Type, 'Tech';

exit;

