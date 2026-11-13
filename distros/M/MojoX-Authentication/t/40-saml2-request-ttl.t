use v5.24;
use warnings;
use Test::More;
use FindBin qw< $Bin >;

eval { require Net::SAML2; Net::SAML2->VERSION(0.86); 1 }
   or plan skip_all => 'Net::SAML2 0.86 not available';

require MojoX::Authentication::Model::SAML2;

my $saml2 = MojoX::Authentication::Model::SAML2->new(
   idp => "$Bin/../eg/idp.xml",
   sp_configuration => {
      identifier => 'https://srv.example.com/sp',
      key        => "$Bin/../eg/server.key",
   },
   request_ttl => 60,
);

# a request issued 45 seconds ago is still within request_ttl
my $id = 'test-request-id';
$saml2->cache->set({ ts => time() - 45 }, $saml2->_key(authnreq_id => $id), time() + 15);

eval { $saml2->parse_assertion($id, 'not-really-a-response') };
my $error = $@;  # copy: the eval below resets $@
my $data = eval { $error->data } // '';
isnt $data, 'expired id', 'request is not considered expired before request_ttl';

done_testing();
