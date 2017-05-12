package Net::Iugu::Customers;
$Net::Iugu::Customers::VERSION = '0.000002';
use Moo;
extends 'Net::Iugu::CRUD';

1;

# ABSTRACT: Net::Iugu::Customers - Methods to manage customers

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Iugu::Customers - Net::Iugu::Customers - Methods to manage customers

=head1 VERSION

version 0.000002

=head1 SYNOPSIS

Implements the API calls to manage customers of Iugu accounts. It is used
by the main module L<Net::Iugu> and shouldn't be instantiated directly.

    use Net::Iugu::Customers;

    my $customers = Net::Iugu::Customers->new(
        token => 'my_api_token'
    );

    my $res;

    $res = $customers->create( $data );
    $res = $customers->read( $customer_id );
    $res = $customers->update( $customer_id, $data );
    $res = $customers->delete( $customer_id );
    $res = $customers->list( $params );

For a detailed reference of params and return values check the
L<Official Documentation|http://iugu.com/referencias/api#clientes>.

=head1 METHODS

=head2 create( $data )

Inherited from L<Net::Iugu::CRUD>, creates a new customer.

=head2 read( $customer_id )

Inherited from L<Net::Iugu::CRUD>, returns data of a customer.

=head2 update( $customer_id, $data )

Inherited from L<Net::Iugu::CRUD>, updates a customer.

=head2 delete( $customer_id )

Inherited from L<Net::Iugu::CRUD>, removes a customer.

=head2 list( $params )

Inherited from L<Net::Iugu::CRUD>, lists all customers.

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
