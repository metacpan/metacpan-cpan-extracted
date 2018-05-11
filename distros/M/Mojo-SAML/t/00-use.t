use Mojo::Base -strict;

use Test::More;

use Mojo::SAML; # loads the documents
use Mojo::SAML::IdP;
use Mojo::SAML::Names;
use Mojo::XMLSig;

ok 1, 'all modules loaded';

done_testing;
