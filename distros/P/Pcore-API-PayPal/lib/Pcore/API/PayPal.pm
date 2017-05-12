package Pcore::API::PayPal v0.1.2;

use Pcore -dist, -class, -result, -const;
use Pcore::Util::Data qw[from_json to_json to_b64];

const our $SANDBOX_ENDPOINT => 'https://api.sandbox.paypal.com';
const our $LIVE_ENDPOINT    => 'https://api.paypal.com';

has id      => ( is => 'ro', isa => Str,  required => 1 );
has secret  => ( is => 'ro', isa => Str,  required => 1 );
has sandbox => ( is => 'ro', isa => Bool, default  => 1 );

has _access_token => ( is => 'ro', isa => Str, init_arg => undef );

sub _get_access_token ( $self, $cb ) {
    if ( $self->{_access_token} && $self->{_access_token}->{expires} > time ) {
        $cb->( $self->{_access_token} );

        return;
    }

    P->http->post(
        ( $self->{sandbox} ? $SANDBOX_ENDPOINT : $LIVE_ENDPOINT ) . '/v1/oauth2/token',
        headers => {
            CONTENT_TYPE  => 'application/x-www-form-urlencoded',
            ACCCEPT       => 'application/json',
            AUTHORIZATION => 'Basic ' . to_b64( "$self->{id}:$self->{secret}", q[] ),
        },
        body      => 'grant_type=client_credentials',
        on_finish => sub ($res) {
            $self->{_access_token} = from_json $res->body;

            warn dump [ scalar $res, $self->{_access_token} ];

            $self->{_access_token}->{expires} = time + $self->{_access_token}->{expires_in} - 5;

            $cb->( $self->{_access_token} );

            return;
        }
    );

    return;
}

# https://developer.paypal.com/docs/api/payments/#payment_create
sub create_payment ( $self, $payment, $cb ) {
    $self->_get_access_token(
        sub ($access_token) {
            my $url = ( $self->{sandbox} ? $SANDBOX_ENDPOINT : $LIVE_ENDPOINT ) . '/v1/payments/payment';

            P->http->post(
                $url,
                headers => {
                    CONTENT_TYPE  => 'application/json',
                    ACCCEPT       => 'application/json',
                    AUTHORIZATION => "$access_token->{token_type} $access_token->{access_token}",
                },
                body      => to_json($payment),
                on_finish => sub ($res) {
                    my $api_res;

                    if ( !$res ) {
                        my $data = $res->body ? from_json $res->body : {};

                        $api_res = result [ $res->status, $data->{message} // $res->reason ];
                    }
                    else {
                        my $data = from_json $res->body;

                        if ( $data->{state} eq 'failed' ) {
                            $api_res = result [ 400, $data->{failure_reason} ], $data;
                        }
                        else {
                            $api_res = result 200, $data;
                        }
                    }

                    $cb->($api_res);

                    return;
                }
            );

            return;
        }
    );

    return;
}

# https://developer.paypal.com/docs/api/payments/#payment_execute
sub exec_payment ( $self, $payment_id, $payer_id, $cb ) {
    $self->_get_access_token(
        sub ($access_token) {
            my $url = ( $self->{sandbox} ? $SANDBOX_ENDPOINT : $LIVE_ENDPOINT ) . "/v1/payments/payment/$payment_id/execute";

            P->http->post(
                $url,
                headers => {
                    CONTENT_TYPE  => 'application/json',
                    ACCCEPT       => 'application/json',
                    AUTHORIZATION => "$access_token->{token_type} $access_token->{access_token}",
                },
                body      => to_json( { payer_id => $payer_id } ),
                on_finish => sub ($res) {
                    my $api_res;

                    if ( !$res ) {
                        my $data = $res->body ? from_json $res->body : {};

                        $api_res = result [ $res->status, $data->{message} // $res->reason ];
                    }
                    else {
                        my $data = from_json $res->body;

                        if ( $data->{state} eq 'failed' ) {
                            $api_res = result [ 400, $data->{failure_reason} ], $data;
                        }
                        else {
                            $api_res = result 200, $data;
                        }
                    }

                    $cb->($api_res);

                    return;
                }
            );

            return;
        }
    );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 93                   | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::PayPal

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by zdm.

=cut
