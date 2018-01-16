package Net::ACME2::JWTMaker::ECC;

use strict;
use warnings;

use parent qw( Net::ACME2::JWTMaker );

sub _ALG {
    my ($self) = @_;

    return $self->{'key'}->get_jwa_alg();
}

sub _get_signer {
    my ($self) = @_;

    return sub {
        return $self->{'key'}->sign_jwa(@_);
    };
}

1;
