use strict;
use warnings;

package Net::FreshBooks::API::Invoice;
$Net::FreshBooks::API::Invoice::VERSION = '0.24';
use Moose;
extends 'Net::FreshBooks::API::Base';
with 'Net::FreshBooks::API::Role::CRUD';
with 'Net::FreshBooks::API::Role::LineItem';
with 'Net::FreshBooks::API::Role::SendBy';

has $_ => ( is => _fields()->{$_}->{is} ) for sort keys %{ _fields() };

sub _fields {
    return {

        amount    => { is => 'ro' },
        client_id => { is => 'rw' },
        contacts  => {
            is           => 'rw',
            made_of      => 'Net::FreshBooks::API::Client::Contact',
            presented_as => 'array',
        },
        currency_code => { is => 'rw' },
        date          => { is => 'rw' },
        discount      => { is => 'rw' },
        first_name    => { is => 'rw' },
        language      => { is => 'rw' },
        last_name     => { is => 'rw' },
        notes         => { is => 'rw' },
        organization  => { is => 'rw' },
        p_city        => { is => 'rw' },
        p_code        => { is => 'rw' },
        p_country     => { is => 'rw' },
        p_state       => { is => 'rw' },
        p_street1     => { is => 'rw' },
        p_street2     => { is => 'rw' },
        po_number     => { is => 'rw' },
        status        => { is => 'rw' },
        terms         => { is => 'rw' },
        vat_name      => { is => 'rw' },
        vat_number    => { is => 'rw' },

        # custom fields
        amount_outstanding => { is => 'ro' },
        folder             => { is => 'ro' },
        invoice_id         => { is => 'ro' },
        lines              => {
            is           => 'rw',
            made_of      => 'Net::FreshBooks::API::InvoiceLine',
            presented_as => 'array',
        },
        links => {
            is           => 'ro',
            made_of      => 'Net::FreshBooks::API::Links',
            presented_as => 'single',
        },
        number       => { is => 'rw' },
        recurring_id => { is => 'ro' },
        return_uri   => { is => 'rw' },
        updated      => { is => 'ro' },

    };
}

__PACKAGE__->meta->make_immutable();

1;

# ABSTRACT: FreshBooks Invoice access

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::Invoice - FreshBooks Invoice access

=head1 VERSION

version 0.24

=head1 SYNOPSIS

    my $fb = Net::FreshBooks::API->new({ ... });
    my $invoice = $fb->invoice;

=head2 create

Create an invoice in the FreshBooks system.

my $invoice = $fb->invoice->create({...});

=head2 get

    my $invoice = $fb->invoice->get({ invoice_id => $invoice_id });

=head2 delete

    my $invoice = $fb->invoice->get({ invoice_id => $invoice_id });
    $invoice->delete;

=head2 update

    # update after edits
    $invoice->organization('Perl Foundation');
    $invoice->update;

    # or immediately
    $invoice->update( { organization => 'Perl Foundation', } );

=head2 links

Returns a L<Net::FreshBooks::API::Links> object, which returns FreshBooks
URLs.

    print "send this url to client: " . $invoice->links->client_view;

=head2 list

Returns a L<Net::FreshBooks::API::Iterator> object.

    # list unpaid invoices
    my $invoices = $fb->invoice->list({ status => 'unpaid' });

    while ( my $invoice = $invoices->next ) {
        print $invoice->invoice_id, "\n";
    }

=head2 lines

Returns an ARRAYREF of Net::FreshBooks::API::InvoiceLine objects

    foreach my $line ( @{ $invoice->lines } ) {
        print $line->amount, "\n";
    }

=head2 add_line

Create a new L<Net::FreshBooks::API::InvoiceLine> object and add it to the end
of the list of lines

    my $bool = $invoice->add_line(
        {   name         => "Yard Work",          # (Optional)
            description  => "Mowed the lawn.",    # (Optional)
            unit_cost    => 10,                   # Default is 0
            quantity     => 4,                    # Default is 0
            tax1_name    => "GST",                # (Optional)
            tax2_name    => "PST",                # (Optional)
            tax1_percent => 8,                    # (Optional)
            tax2_percent => 6,                    # (Optional)
        }
    );

=head2 send_by_email

Send the invoice by email.

  my $result = $invoice->send_by_email();

=head2 send_by_snail_mail

Send the invoice by snail mail.

  my $result = $invoice->send_by_snail_mail();

=head1 DESCRIPTION

This class gives you access to FreshBooks invoice information.
L<Net::FreshBooks::API> will construct this object for you.

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
