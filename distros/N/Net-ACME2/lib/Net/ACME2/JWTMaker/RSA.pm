package Net::ACME2::JWTMaker::RSA;

use strict;
use warnings;

use parent qw( Net::ACME2::JWTMaker );

use constant _ALG => 'RS256';

#Based on Crypt::JWT::encode_jwt(), but focused on this particular
#protocol’s needs. Note that UTF-8 might get mangled in here,
#but that’s not a problem since ACME shouldn’t require sending raw UTF-8.
#(Maybe with registration??)
sub _get_signer {
    my ( $self ) = @_;

    return sub {
        return $self->{'key'}->can('sign_' . _ALG())->($self->{'key'}, @_);
    };
}

1;
