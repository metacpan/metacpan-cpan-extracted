use strict;
use warnings;

package Net::FreshBooks::API::Links;
$Net::FreshBooks::API::Links::VERSION = '0.24';
use Moose;
extends 'Net::FreshBooks::API::Base';

has $_ => ( is => _fields()->{$_}->{is} ) for sort keys %{ _fields() };

sub _fields {
    return {
        client_view => { is => 'ro' },
        view        => { is => 'ro' },
        edit        => { is => 'ro' },
        statement   => { is => 'ro' },
    };
}

__PACKAGE__->meta->make_immutable();

1;

# ABSTRACT: Provides FreshBooks Link objects to Clients and Invoices

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::Links - Provides FreshBooks Link objects to Clients and Invoices

=head1 VERSION

version 0.24

=head1 SYNOPSIS

    my $fb = Net::FreshBooks::API->new(...);
    my $invoice = $fb->invoice->get({ invoice_id => $invoice_id });
    my $links = $invoice->links;

    print "Send this link to client: " . $links->client_view;

    my $client = $fb->client->get({ client_id => $client_id });
    print "Client view: " . $client->links->client_view;

=head2 client_view

    Provided for invoice, client and estimate links.

=head2 view

    Provided for invoice and client links.

=head2 edit

    Provided for invoice links.

=head2 statement

    Provided for client links.

=head1 DESCRIPTION

The methods on this object all return FreshBooks URLs.

=head1 AUTHORS

=over 4

=item *

Edmund von der Burg <evdb@ecclestoad.co.uk>

=item *

Olaf Alders <olaf@wundercounter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Edmund von der Burg & Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
