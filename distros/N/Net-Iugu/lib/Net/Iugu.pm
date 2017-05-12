package Net::Iugu;
$Net::Iugu::VERSION = '0.000002';
use Moo;
extends 'Net::Iugu::Request';

use Net::Iugu::Customers;
use Net::Iugu::PaymentMethods;
use Net::Iugu::Invoices;
use Net::Iugu::MarketPlace;
use Net::Iugu::Plans;
use Net::Iugu::Subscriptions;
use Net::Iugu::Transfers;

has 'token' => (
    is       => 'ro',
    required => 1,
);

has 'customers' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { Net::Iugu::Customers->new( token => shift->token ) },
);

has 'payment_methods' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { Net::Iugu::PaymentMethods->new( token => shift->token ) },
);

has 'invoices' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { Net::Iugu::Invoices->new( token => shift->token ) },
);

has 'market_place' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { Net::Iugu::MarketPlace->new( token => shift->token ) },
);

has 'plans' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { Net::Iugu::Plans->new( token => shift->token ) },
);

has 'subscriptions' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { Net::Iugu::Subscriptions->new( token => shift->token ) },
);

has 'transfers' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { Net::Iugu::Transfers->new( token => shift->token ) },
);

sub create_token {
    my ( $self, $data ) = @_;

    my $uri = $self->base_uri . '/payment_token';

    return $self->request( POST => $uri, $data );
}

sub charge {
    my ( $self, $data ) = @_;

    my $uri = $self->base_uri . '/charge';

    return $self->request( POST => $uri, $data );
}

1;

# ABSTRACT: Perl modules for integration with Iugu payment web services

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Iugu - Perl modules for integration with Iugu payment web services

=head1 VERSION

version 0.000002

=head1 SYNOPSIS

Implements the API calls to Iugu payment services.

    use Net::Iugu;

    my $api = Net::Iugu->new( token => 'my_api_token' );

    my $res;

    $res = $api->customers->create( $data );
    $res = $api->customers->read( $customer_id );
    $res = $api->customers->update( $customer_id, $data );
    $res = $api->customers->delete( $customer_id );
    $res = $api->customers->list( $params );
    
    $res = $api->payment_methods->create( $data );
    $res = $api->payment_methods->read(   $customer_id, $method_id );
    $res = $api->payment_methods->update( $customer_id, $method_id, $data );
    $res = $api->payment_methods->delete( $customer_id, $method_id );
    $res = $api->payment_methods->list( $params );

    $res = $api->invoices->create( $data );
    $res = $api->invoices->read( $invoice_id );
    $res = $api->invoices->update( $invoice_id, $data );
    $res = $api->invoices->delete( $invoice_id );
    $res = $api->invoices->cancel( $invoice_id );
    $res = $api->invoices->refund( $invoice_id );
    $res = $api->invoices->list( $params );

    $res = $api->market_place->create_account( $data );
    $res = $api->market_place->request_account_verification( $user_token, $account_id, $data );
    $res = $api->market_place->account_info( $account_id );
    $res = $api->market_place->configurate_account( $user_token, $data );
    $res = $api->market_place->request_withdraw( $account_id, $amount );
   
    $res = $api->plans->create( $data );
    $res = $api->plans->read( $plan_id );
    $res = $api->plans->read_by_identifier( $plan_id );
    $res = $api->plans->update( $plan_id, $data );
    $res = $api->plans->delete( $plan_id );
    $res = $api->plans->list( $params );

    $res = $api->subscriptions->create( $data );
    $res = $api->subscriptions->read( $subscription_id );
    $res = $api->subscriptions->update( $subscription_id, $data );
    $res = $api->subscriptions->delete( $subscription_id );
    $res = $api->subscriptions->list( $params );
    $res = $api->subscriptions->suspend( $subscription_id );
    $res = $api->subscriptions->activate( $subscription_id );
    $res = $api->subscriptions->change_plan( $subscription_id, $plan_id );
    $res = $api->subscriptions->add_credits( $subscription_id, $amount );
    $res = $api->subscriptions->remove_credits( $subscription_id, $amount );

    $res = $api->transfers->transfer( $data );
    $res = $api->transfers->list;

    $res = $api->create_token( $data );
    $res = $api->charge( $data );

For a detailed reference of params and return values check the
L<Official Documentation|http://iugu.com/referencias/api>.

For a detailed reference of params and return values of methods
C<create_token> and c<charge> check the
L<documentation of them|http://iugu.com/referencias/api#tokens-e-cobranca-direta>.

Aditionally, check the document of each auxiliar module: L<Net::Iugu::Customers>,
L<Net::Iugu::PaymentMethods>, L<Net::Iugu::Invoices>, L<Net::Iugu::MarketPlace>,
L<Net::Iugu::Plans>, L<Net::Iugu::Subscriptions> and L<Net::Iugu::Transfers>.

=head1 METHODS

=head2 create_token( $data )

Creates a payment token for use with direct charges.

=head2 charge( $data )

Charges directly the credit card of a client or generates a bank slip.

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
