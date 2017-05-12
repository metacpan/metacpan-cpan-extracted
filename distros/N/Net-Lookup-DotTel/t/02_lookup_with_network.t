use Test::More tests => 14;

use Net::Lookup::DotTel;
use Net::DNS;

# The test domain is owned by the author and should have the fields tested
# here associated with it.
use constant TEST_DOMAIN => 'telnic.tel';

# Find out whether we can do any lookups at all.
my $dns = Net::DNS::Resolver->new;
ok ( $dns, 'Net::DNS::Resolver->new()' );

SKIP: {

  my $response = $dns->query ( TEST_DOMAIN, 'NS' );
  skip ( 'network lookup tests - no response from resolver, not connected to the internet?', 14 )
    unless ( $response );

  skip ( 'domain parsing tests - domain name ' . TEST_DOMAIN . ' not found', 14 )
    unless (( $response->question )[0]->qname eq TEST_DOMAIN );

  my $lookup = Net::Lookup::DotTel->new;
  
  ok ( $lookup->lookup ( TEST_DOMAIN ), 'lookup() with valid domain' );
  
  my @keywords = $lookup->get_keywords;
  ok (( ref $keywords[0] eq 'ARRAY' ), 'get_keywords()' );

  my @postal_addresses = $lookup->get_postal_address;
  my $address = $postal_addresses[0];

  ok (( ref $address eq 'HASH' ), 'get_postal_address()' );

  ok (( ref $address->{order} eq 'ARRAY' ), 'get_postal_address() order field' );
  ok ( $address->{address1}, 'get_postal_address() address1 field' );
  ok ( $address->{postcode}, 'get_postal_address() postcode field' );
  ok ( $address->{city}, 'get_postal_address() city field' );

  my @services = $lookup->get_services;
  my $service = $services[0];

  ok (( ref $service eq 'HASH' ), 'get_services()' );
  ok (( ref $service->{services} eq 'ARRAY' ), 'get_services() services field' );
  ok (( $service->{uri} =~ /^[a-z]+:.+/i ), 'get_services() uri field' );
  ok (( defined $service->{order} ), 'get_services() order field' );
  ok (( defined $service->{preference} ), 'get_services() preference field' );
  
  my @text = $lookup->get_text;
  ok ( scalar @text, 'get_text()' );  

}

