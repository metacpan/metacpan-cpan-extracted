use strict; use warnings;

package Net::OAuth2Server::TokenType;

our $VERSION = '0.003';

use constant ();
use Exporter ();

our %TOKEN_TYPE = (
	TOKEN_TYPE_JWT           => 'urn:ietf:params:oauth:token-type:jwt',
	TOKEN_TYPE_ACCESS_TOKEN  => 'urn:ietf:params:oauth:token-type:access_token',
	TOKEN_TYPE_REFRESH_TOKEN => 'urn:ietf:params:oauth:token-type:refresh_token',
	TOKEN_TYPE_ID_TOKEN      => 'urn:ietf:params:oauth:token-type:id_token',
	TOKEN_TYPE_SAML1         => 'urn:ietf:params:oauth:token-type:saml1',
	TOKEN_TYPE_SAML2         => 'urn:ietf:params:oauth:token-type:saml2',
);

constant->import( \%TOKEN_TYPE );
*import = \&Exporter::import;
our @EXPORT_OK = sort keys %TOKEN_TYPE;

1;
