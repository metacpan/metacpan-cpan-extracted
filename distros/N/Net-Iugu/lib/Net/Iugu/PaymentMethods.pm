package Net::Iugu::PaymentMethods;
$Net::Iugu::PaymentMethods::VERSION = '0.000002';
use Moo;
extends 'Net::Iugu::CRUD';

sub create {
    my ( $self, $customer_id, $data ) = @_;

    my $uri = $self->_uri($customer_id);

    return $self->request( POST => $uri, $data );
}

sub read {
    my ( $self, $customer_id, $payment_method_id ) = @_;

    my $uri = $self->_uri( $customer_id, $payment_method_id );

    return $self->request( GET => $uri );
}

sub update {
    my ( $self, $customer_id, $payment_method_id, $data ) = @_;

    my $uri = $self->_uri( $customer_id, $payment_method_id );

    return $self->request( PUT => $uri, $data );
}

sub delete {
    my ( $self, $customer_id, $payment_method_id ) = @_;

    my $uri = $self->_uri( $customer_id, $payment_method_id );

    return $self->request( DELETE => $uri );
}

sub list {
    my ( $self, $customer_id ) = @_;

    my $uri = $self->_uri($customer_id);

    return $self->request( GET => $uri );
}

sub _uri {
    my ( $self, $customer_id, $payment_method_id ) = @_;

    my @parts = (
        $self->base_uri,       ##
        'customers',           ##
        $customer_id,          ##
        'payment_methods',     ##
        $payment_method_id,    ##
    );

    return join '/', grep { !!$_ } @parts;
}

1;

# ABSTRACT: Net::Iugu::PaymentMethods - Methods to manage payment methods

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Iugu::PaymentMethods - Net::Iugu::PaymentMethods - Methods to manage payment methods

=head1 VERSION

version 0.000002

=head1 SYNOPSIS

Implements the API calls to manage payment mathods of Iugu accounts. It is used
by the main module L<Net::Iugu> and shouldn't be instantiated directly.

    use Net::Iugu::PaymentMethods;

    my $methods = Net::Iugu::PaymentMethods->new(
        token => 'my_api_token'
    );

    my $res;

    $res = $methods->create( $data );
    $res = $methods->read(   $customer_id, $method_id );
    $res = $methods->update( $customer_id, $method_id, $data );
    $res = $methods->delete( $customer_id, $method_id );
    $res = $methods->list( $params );

For a detailed reference of params and return values check the
L<Official Documentation|http://iugu.com/referencias/api#formas-de-pagamento-de-cliente>.

=head1 METHODS

=head2 create( $data )

Creates a new payment method for a client.

=head2 read( $customer_id, $payment_method_id )

Returns data of a payment method of a client.

=head2 update( $customer_id, $payment_method_id, $data )

Updates a payment method of a client.

=head2 delete( $customer_id, $payment_method_id )

Removes a payment method of a client.

=head2 list( $customer_id, $params )

Lists all payment methods of a client.

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
