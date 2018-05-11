use Mojo::Base -strict;

use Mojo::SAML::IdP;

my $url = shift || die 'please pass in a url of an idp entity';
my $idp = Mojo::SAML::IdP->new->from_url($url);

say $idp->entity_id;
say $idp->location_for('SingleSignOnService', 'HTTP-POST');
say $idp->key_for('signing');
say $idp->name_id_format('transient');
say $idp->default_id_format;

say $idp->verify_signature;

