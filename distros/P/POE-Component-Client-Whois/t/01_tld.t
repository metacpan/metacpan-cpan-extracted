use Test::More tests => 9;

use_ok("POE::Component::Client::Whois::TLDList");
my $tld = POE::Component::Client::Whois::TLDList->new();
isa_ok( $tld, "POE::Component::Client::Whois::TLDList" );

my %tests = (
  'bingosnet.co.uk', 'whois.nic.uk',
  'bingosnet.com', 'whois.crsnic.net',
  'bingosnet.ao', 'NONE',
  'bingosnet.arpa', 'whois.iana.org',
  '1.0.0.100.in-addr.arpa', 'ARPA',
  'bingosnet.cy', 'WEB',
  'bingosnet.DE', 'de.whois-servers.net',
);

foreach my $test ( sort keys %tests ) {
   my @result = $tld->tld( $test );
   is ( $result[0], $tests{ $test }, "TLD test for '$test'" );
}
