use strict;
use warnings;

package Net::FreshBooks::API::Role::LineItem;
$Net::FreshBooks::API::Role::LineItem::VERSION = '0.24';
use Moose::Role;
use Net::FreshBooks::API::InvoiceLine;
use Data::Dump qw( dump );

sub add_line {
    my $self      = shift;
    my $line_args = shift;

    push @{ $self->{lines} ||= [] },
        Net::FreshBooks::API::InvoiceLine->new( $line_args );

    return 1;
}

1;

# ABSTRACT: Line Item roles

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::Role::LineItem - Line Item roles

=head1 VERSION

version 0.24

=head1 SYNOPSIS

Provides line item functionality to Invoices and Estimates. See those modules
for specific examples of how to use this method.

=head2 add_line( $args)

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
