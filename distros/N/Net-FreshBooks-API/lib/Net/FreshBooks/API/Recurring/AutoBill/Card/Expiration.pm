use strict;
use warnings;

package Net::FreshBooks::API::Recurring::AutoBill::Card::Expiration;
$Net::FreshBooks::API::Recurring::AutoBill::Card::Expiration::VERSION = '0.24';
use Moose;
extends 'Net::FreshBooks::API::Base';

has $_ => ( is => _fields()->{$_}->{is} ) for sort keys %{ _fields() };

sub node_name { return 'expiration' }

sub _fields {
    return {
        month => { is => 'rw' },
        year  => { is => 'rw' },
    };
}

# make sure unitialized objects don't make the cut
sub _validates {

    my $self = shift;

    return ( $self->month && $self->year );

}

__PACKAGE__->meta->make_immutable();

1;

# ABSTRACT: FreshBooks Autobill Credit Card Expiration access

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::Recurring::AutoBill::Card::Expiration - FreshBooks Autobill Credit Card Expiration access

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
