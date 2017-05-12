package Net::Flotum::API::Charge;
use common::sense;
use Moo;
use namespace::clean;
use MooX::late;
use Carp;
use JSON::MaybeXS;
use Net::Flotum::API::ExceptionHandler;

has flotum => (
    is       => "ro",
    weak_ref => 1,
);

sub exec_new_charge {
    my ( $self, %args ) = @_;

    my $customer = delete $args{customer};
    croak "missing 'customer'" unless defined $customer;

    my $customer_id = $customer->id;

    my %ret = request_with_retries(
        logger    => $self->flotum->logger,
        requester => $self->flotum->requester,
        name      => 'new charge',
        method    => 'rest_post',
        params    => [
            join( "/", 'customers', $customer_id, 'charges' ),
            headers => [
                'Content-Type' => 'application/json',
                'X-api-key'    => $self->flotum->merchant_api_key,
            ],
            code => 201,
            data => encode_json( {%args} )
        ]
    );

    if (%ret) {

        return Net::Flotum::Object::Charge->new(
            flotum   => $self->flotum,
            customer => $customer,
            id       => $ret{obj}{id}
        );

    }
    return;
}

sub exec_payment_charge {
    my ( $self, %args ) = @_;

    # Required args.
    for (qw(charge)) {
        croak "missing '$_'" unless defined $args{$_};
    }

    my $charge = delete $args{charge};

    my $customer_id = $charge->customer->id;
    my $charge_id   = $charge->id;

    my %ret = request_with_retries(
        logger    => $self->flotum->logger,
        requester => $self->flotum->requester,
        name      => 'payment charge',
        method    => 'rest_post',
        params    => [
            join( "/", 'customers', $customer_id, 'charges', $charge_id, 'payment' ),
            headers => [
                'Content-Type' => 'application/json',
                'X-api-key'    => $self->flotum->merchant_api_key,
            ],
            code => 202,
            data => encode_json( \%args )
        ]
    );

    if (%ret) {
        return $ret{obj};
    }
    return;
}

sub exec_capture_charge {
    my ( $self, %args ) = @_;

    my $charge = delete $args{charge};

    my $customer_id = $charge->customer->id;
    my $charge_id   = $charge->id;

    my %ret = request_with_retries(
        logger    => $self->flotum->logger,
        requester => $self->flotum->requester,
        name      => 'capture charge',
        method    => 'rest_post',
        params    => [
            join( "/", 'customers', $customer_id, 'charges', $charge_id, 'capture' ),
            headers => [
                'Content-Type' => 'application/json',
                'X-api-key'    => $self->flotum->merchant_api_key,
            ],
            code => 202,
            data => encode_json( \%args )
        ]
    );

    if (%ret) {
        return $ret{obj};
    }
    return;
}

sub exec_refund_charge {
    my ( $self, %args ) = @_;

    my $charge = delete $args{charge};

    my $customer_id = $charge->customer->id;
    my $charge_id   = $charge->id;

    my %ret = request_with_retries(
        logger    => $self->flotum->logger,
        requester => $self->flotum->requester,
        name      => 'refund charge',
        method    => 'rest_post',
        params    => [
            join( "/", 'customers', $customer_id, 'charges', $charge_id, 'refund' ),
            headers => [
                'Content-Type' => 'application/json',
                'X-api-key'    => $self->flotum->merchant_api_key,
            ],
            code => 202,
            data => '{}'
        ]
    );

    if (%ret) {
        return $ret{obj};
    }
    return;
}

1;
