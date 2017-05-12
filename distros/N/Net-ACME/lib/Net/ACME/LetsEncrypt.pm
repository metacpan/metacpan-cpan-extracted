package Net::ACME::LetsEncrypt;

use strict;
use warnings;

use parent qw(Net::ACME);

use Net::ACME::HTTP ();

use constant STAGING_SERVER => 'acme-staging.api.letsencrypt.org';

use constant PRODUCTION_SERVER => 'acme-v01.api.letsencrypt.org';

*_HOST = \&PRODUCTION_SERVER;

#https://community.letsencrypt.org/t/terms-of-service-without-registration/21328/2
sub get_terms_of_service {
    my ($self) = @_;

    my $host = $self->_HOST();

    my $resp = Net::ACME::HTTP->new()->get("https://$host/terms");

    return $resp->header('location');
}

1;
