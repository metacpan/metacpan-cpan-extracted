use strict;
use warnings;

package Net::FreshBooks::API::InvoiceLine;
$Net::FreshBooks::API::InvoiceLine::VERSION = '0.24';
use Moose;
extends 'Net::FreshBooks::API::Base';

has $_ => ( is => _fields()->{$_}->{is} ) for sort keys %{ _fields() };

sub node_name { return 'line' }

sub _fields {
    return {
        line_id      => { is => 'ro' },
        amount       => { is => 'ro' },
        name         => { is => 'rw' },
        description  => { is => 'rw' },
        unit_cost    => { is => 'rw' },
        quantity     => { is => 'rw' },
        tax1_name    => { is => 'rw' },
        tax2_name    => { is => 'rw' },
        tax1_percent => { is => 'rw' },
        tax2_percent => { is => 'rw' },
        type         => { is => 'rw' },
    };
}

__PACKAGE__->meta->make_immutable();

1;

# ABSTRACT: Adds Line Item support to FreshBooks Invoices

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::InvoiceLine - Adds Line Item support to FreshBooks Invoices

=head1 VERSION

version 0.24

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
