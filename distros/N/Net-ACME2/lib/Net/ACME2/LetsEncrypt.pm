package Net::ACME2::LetsEncrypt;

use strict;
use warnings;

use parent qw( Net::ACME2 );

=encoding utf-8

=head1 NAME

Net::ACME2::LetsEncrypt - Let’s Encrypt’s v2 API endpoint

=head1 SYNOPSIS

See L<Net::ACME2> for usage examples.

=cut

use constant {
    _STAGING_SERVER    => 'acme-staging-v02.api.letsencrypt.org',
    _PRODUCTION_SERVER => 'acme-v02.api.letsencrypt.org',
};

use constant {
    DIRECTORY_PATH => '/directory',

    #JWS_FORMAT => 'compact',   #v1 supported this?
};

*HOST = *_PRODUCTION_SERVER;

1;
