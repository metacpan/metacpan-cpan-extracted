#!perl -T

use Test::More tests => 3;

use Net::validMX qw(get_domain_from_email);

#DOMAIN EXTRACTION
is( &get_domain_from_email('kevin.mcgrail@peregrinehw.com'), 'peregrinehw.com', 'Test for email domain extraction');

#LOCAL EXTRACTION WITH WANTARRAY
my ($local, $domain) = &get_domain_from_email('kevin.mcgrail@peregrinehw.com');

is( $local, 'kevin.mcgrail', 'Test for email local part extraction with array return');

is( $domain, 'peregrinehw.com', 'Test for email domain extraction with array reutn');

