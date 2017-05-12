use strict;
use warnings;

package Net::FreshBooks::API::Gateway;
$Net::FreshBooks::API::Gateway::VERSION = '0.24';
use Moose;
extends 'Net::FreshBooks::API::Base';

# gateway does not provide "get"
with 'Net::FreshBooks::API::Role::Iterator' => { -excludes => 'get' };

has $_ => ( is => _fields()->{$_}->{is} ) for sort keys %{ _fields() };

sub _fields {
    return {
        name             => { is => 'ro' },
        autobill_capable => { is => 'ro' },
    };
}

__PACKAGE__->meta->make_immutable();

1;

# ABSTRACT: List gateways available in your FreshBooks account

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::Gateway - List gateways available in your FreshBooks account

=head1 VERSION

version 0.24

=head1 SYNOPSIS

    my $fb = Net::FreshBooks::API->new(...);
    my $gateways = $fb->gateway->get_all();

    # or
    my $autobill_gateways = $fb->gateway->get_all({ autobill_capable => 1 });

=head2 list

Returns an L<Net::FreshBooks::API::Iterator> object. Currently, all list()
functionality defaults to 15 items per page.

    # list all gateways
    my $gateways = $fb->gateway->list();

    print $gateways->total . " gateways\n";
    print $gateways->pages . " pages of results\n";

    while ( my $gateway = $gateways->next ) {
        print join( "\t", $gateway->name, $gateway->autobill_capable ) . "\n";
    }

=head2 get_all

Returns an ARRAYREF of all possible results, handling pagination for you.

=head1 DESCRIPTION

Returns a list of payment gateways enabled in your FreshBooks account that can
process credit card transactions. You can optionally filter by
autobill_capable to return only gateways that support auto-bills. See
L<http://developers.freshbooks.com/docs/gateway/> for more info.

You should note that there is no "get" method for Gateways as the API does not
provide it.

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
