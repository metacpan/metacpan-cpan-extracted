package Pcore::API::Google::OAuth;

use Pcore -class, -const, -res;
use Crypt::OpenSSL::RSA qw[];
use Pcore::Util::Scalar qw[is_ref];
use Pcore::Util::Data qw[to_b64u to_json from_json to_uri];

has key   => ( required => 1 );
has scope => ( required => 1 );

has _token       => ( init_arg => undef );
has _openssl_rsa => ( init_arg => undef );

const our $JWT_HEADER => to_b64u to_json {
    alg => 'RS256',
    typ => 'JWT',
};

sub BUILD ( $self, $args ) {
    $self->{key} = P->cfg->read( $self->{key} ) if !is_ref $self->{key};

    $self->{_openssl_rsa} = Crypt::OpenSSL::RSA->new_private_key( $self->{key}->{private_key} );

    $self->{_openssl_rsa}->use_sha256_hash;

    return;
}

# https://developers.google.com/identity/protocols/OAuth2ServiceAccount#authorizingrequests
sub get_token ( $self ) {
    my $token = $self->{_token};

    if ( !$token || $token->{expires} <= time ) {
        my $key = $self->{key};

        my $issue_time = time;

        my $jwt_claim_set = to_b64u to_json {
            aud   => 'https://www.googleapis.com/oauth2/v4/token',
            iss   => $key->{client_email},
            scope => $self->{scope},
            iat   => $issue_time,
            exp   => $issue_time + 3600,
        };

        my $jwt_signature = to_b64u $self->{_openssl_rsa}->sign( $JWT_HEADER . '.' . $jwt_claim_set );

        my $jwt = $JWT_HEADER . '.' . $jwt_claim_set . '.' . $jwt_signature;

        my $res = P->http->post(
            'https://www.googleapis.com/oauth2/v4/token',
            headers => [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
            data    => to_uri {
                grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                assertion  => $jwt,
            },
        );

        if ( !$res ) {
            undef $self->{_token};

            my $error = $res->{data} ? from_json $res->{data} : undef;

            $token = res $res;

            $token->{reason} = $error->{error_description} if $error;
        }
        else {
            $token = $self->{_token} = res 200, from_json $res->{data};

            $token->{expires} = $issue_time + 3600 - 5;
        }
    }

    return $token;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Google::OAuth

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
