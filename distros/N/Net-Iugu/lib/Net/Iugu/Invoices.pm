package Net::Iugu::Invoices;
$Net::Iugu::Invoices::VERSION = '0.000002';
use Moo;
extends 'Net::Iugu::CRUD';

sub cancel {
    my ( $self, $invoice_id ) = @_;

    my $uri = $self->endpoint . '/' . $invoice_id . '/cancel';

    return $self->request( PUT => $uri );
}

sub refund {
    my ( $self, $invoice_id ) = @_;

    my $uri = $self->endpoint . '/' . $invoice_id . '/refund';

    return $self->request( POST => $uri );
}

1;

# ABSTRACT: Net::Iugu::Invoices - Methods to manage invoices

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Iugu::Invoices - Net::Iugu::Invoices - Methods to manage invoices

=head1 VERSION

version 0.000002

=head1 SYNOPSIS

Implements the API calls to manage invoices of Iugu accounts. It is used
by the main module L<Net::Iugu> and shouldn't be instantiated directly.

    use Net::Iugu::Invoices;

    my $invoices = Net::Iugu::Invoices->new(
        token => 'my_api_token'
    );

    my $res;

    $res = $invoices->create( $data );
    $res = $invoices->read( $invoice_id );
    $res = $invoices->update( $invoice_id, $data );
    $res = $invoices->delete( $invoice_id );
    $res = $invoices->cancel( $invoice_id );
    $res = $invoices->refund( $invoice_id );
    $res = $invoices->list( $params );

For a detailed reference of params and return values check the
L<Official Documentation|http://iugu.com/referencias/api#faturas>.

=head1 METHODS

=head2 create( $data )

Inherited from L<Net::Iugu::CRUD>, creates a new invoice.

=head2 read( $invoice_id )

Inherited from L<Net::Iugu::CRUD>, returns data of an invoice.

=head2 update( $invoice_id, $data )

Inherited from L<Net::Iugu::CRUD>, updates an invoice.

=head2 delete( $invoice_id )

Inherited from L<Net::Iugu::CRUD>, removes an invoice.

=head2 cancel( $invoice_id )

Cancels an invoice.

=head2 refund( $invoice_id )

Refunds an invoice.

=head2 list( $params )

Lists all invoices.

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
