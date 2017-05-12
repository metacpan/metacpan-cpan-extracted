package Net::Flotum::API::Customer;
use common::sense;
use Moo;
use namespace::clean;
use Carp;
use JSON::MaybeXS;
use Net::Flotum::Object::Charge;
use Net::Flotum::API::ExceptionHandler;

has 'flotum' => ( is => 'ro', weak_ref => 1 );

sub exec_new_customer {
    my ( $self, %opts ) = @_;

    my $requester = $self->flotum->requester;
    my $logger    = $self->flotum->logger;

    my (%ret) = request_with_retries(
        logger    => $logger,
        requester => $requester,
        name      => 'create user',
        method    => 'rest_post',
        params    => [
            'customers',
            headers => [
                'Content-Type' => 'application/json',
                'X-api-key'    => $self->flotum->merchant_api_key
            ],
            code => 201,
            data => encode_json( \%opts )
        ]
    );

    return $ret{obj};

}

sub exec_load_customer {
    my ( $self, %opts ) = @_;

    my $requester = $self->flotum->requester;
    my $logger    = $self->flotum->logger;

    my ( @with_id, %params );
    push @with_id, $opts{id} if exists $opts{id} and defined $opts{id};
    $params{remote_id} = $opts{remote_id}
      if exists $opts{remote_id} and defined $opts{remote_id};

    my (%ret) = request_with_retries(
        logger    => $logger,
        requester => $requester,
        name      => 'load user',
        method    => 'rest_get',
        params    => [
            [ 'customers', @with_id ],
            params  => \%params,
            headers => [
                'Content-Type' => 'application/json',
                'X-api-key'    => $self->flotum->merchant_api_key
            ],
            code => 200
        ]
    );

    my $obj = $ret{obj};
    $obj = $obj->{customers}[0] if exists $obj->{customers};
    die "Resource does not exists\n" unless $obj->{id};
    return $obj;
}

sub exec_get_customer_session {
    my ( $self, %opts ) = @_;

    my $requester = $self->flotum->requester;
    my $logger    = $self->flotum->logger;

    my (%ret) = request_with_retries(
        logger    => $logger,
        requester => $requester,
        name      => 'get temporary user session',
        method    => 'rest_post',
        params    => [
            ['merchant-customer-sessions'],
            headers => [
                'Content-Type' => 'application/json',
                'X-api-key'    => $self->flotum->merchant_api_key
            ],
            code                => 201,
            automatic_load_item => 0,
            data                => encode_json {
                merchant_customer_id => $opts{id},
                provisional          => 1,           # JSON->true has the same effect
            }
        ]
    );

    return $ret{obj};
}

## i'm not into creathing a API::CreditCard just for this right now.
sub exec_list_credit_cards {
    my ( $self, %opts ) = @_;

    my $requester = $self->flotum->requester;
    my $logger    = $self->flotum->logger;

    my (%ret) = request_with_retries(
        logger    => $logger,
        requester => $requester,
        name      => 'list user credit cards',
        method    => 'rest_get',
        params    => [
            [ 'customers', $opts{id}, 'credit-cards' ],
            headers => [
                'Content-Type' => 'application/json',
                'X-api-key'    => $self->flotum->merchant_api_key
            ],
            code => 200
        ]
    );

    return $ret{obj};
}

## i'm not into creathing a API::CreditCard just for this right now. (2)
sub exec_remove_credit_card {
    my ( $self, %opts ) = @_;

    my $requester = $self->flotum->requester;
    my $logger    = $self->flotum->logger;

    my (%ret) = request_with_retries(
        logger    => $logger,
        requester => $requester,
        name      => 'remove credit one card',
        method    => 'rest_delete',
        params    => [
            [ 'customers', $opts{merchant_customer_id}, 'credit-cards', $opts{id} ],
            headers => [
                'Content-Type' => 'application/json',
                'X-api-key'    => $self->flotum->merchant_api_key
            ],
            code => 204
        ]
    );

    return $ret{obj};
}

sub exec_new_charge {
    my ( $self, %args ) = @_;

    my $ret = $self->flotum->_new_charge->exec_new_charge( customer => $self );

    return $ret;
}

sub exec_update_customer {
    my ( $self, %args ) = @_;

    my $customer = delete $args{customer};
    croak "missing 'customer'" unless defined $customer;

    my $customer_id = $customer->id;

    my %ret = request_with_retries(
        logger    => $self->flotum->logger,
        requester => $self->flotum->requester,
        name      => 'update customer',
        method    => 'rest_put',
        params    => [
            join( "/", 'customers', $customer_id ),
            headers => [
                'Content-Type' => 'application/json',
                'X-api-key'    => $self->flotum->merchant_api_key,
            ],
            code => 202,
            data => encode_json( {%args} )
        ]
    );

    if (%ret) {
        return $ret{obj};
    }
    return;
}

1;
