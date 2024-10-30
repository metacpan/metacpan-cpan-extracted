package Regru::API::Shop;

# ABSTRACT: REG.API v2 domain shop management functions

use strict;
use warnings;
use Moo;
use namespace::autoclean;

our $VERSION = '0.053'; # VERSION
our $AUTHORITY = 'cpan:OLEG'; # AUTHORITY

with 'Regru::API::Role::Client';

has '+namespace' => (
    default => sub { 'shop' },
);

sub available_methods {[qw(
    nop
    add_lot
    update_lot
    delete_lot
    get_info
    get_lot_list
    get_category_list
    get_suggested_tags
)]}

__PACKAGE__->namespace_methods;
__PACKAGE__->meta->make_immutable;

1; # End of Regru::API::Shop

__END__

=pod

=encoding UTF-8

=head1 NAME

Regru::API::Shop - REG.API v2 domain shop management functions

=head1 VERSION

version 0.053

=head1 DESCRIPTION

REG.API domain shop management.

=head1 ATTRIBUTES

=head2 namespace

Always returns the name of category: C<shop>. For internal uses only.

=head1 REG.API METHODS

=head2 nop

For testing purposes. Scope: B<clients>. Typical usage:

    $resp = $client->shop->nop;

Returns success response.

More info at L<Shop management: nop|https://www.reg.com/support/help/api2#shop_nop>.

=head2 add_lot

Puts one or more lots to domain shop.

Scope B<clients>. Typical usage:

    $resp = $client->shop->add_lot(
        description                 => 'great deal: two by one!',
        category_ids                => [qw( 10 15 )],
        rent                        => 0,
        keywords                    => [qw( foo bar baz )],
        price                       => 200,
        lots                        => [
            { price => 201, rent_price => 0, dname => 'foo.com' },
            { price => 203, rent_price => 0, dname => 'bar.net' },
        ],
        sold_with                   => '',
        deny_bids_lower_rejected    => 1,
        lot_price_type              => 'fixed',
    );

Returns success response if lots was added or error otherwise.

More info at L<Shop management: add_lot|https://www.reg.com/support/help/api2#shop_add_lot>.

=head2 update_lot

Updates a lot entry at domain shop.

Scope B<clients>. Typical usage:

    $resp = $client->shop->update_lot(
        dname                       => 'underwood.com',
        description                 => 'For the House of Cards fans only!',
        category_ids                => [qw( 4 10 )],
        rent                        => 0,
        keywords                    => [qw( spacey hoc vp potus )],
        price                       => 2000,
        sold_with                   => 'tm',
        deny_bids_lower_rejected    => 1,
        lot_price_type              => 'offer',
    );

Returns success response if lots was updated or error otherwise.

More info at L<Shop management: update_lot|https://www.reg.com/support/help/api2#shop_update_lot>.

=head2 delete_lot

Deletes the lots from domain shop.

Scope B<clients>. Typical usage:

    $resp = $client->shop->delete_lot(
        dname => [qw( foo.com bar.net )],
    );

Returns success response if lots was deleted or error otherwise.

More info at L<Shop management: delete_lot|https://www.reg.com/support/help/api2#shop_delete_lot>.

=head2 get_info

Retrieves an information on the lot.

Scope B<clients>. Typical usage:

    $resp = $client->shop->get_info(
        dname => 'quux.ru',
    );

Answer will contain the set of metrics (such as C<keywords>, C<start_price>, C<rent_price> etc) for requested
lot.

More info at L<Shop management: get_info|https://www.reg.com/support/help/api2#shop_get_info>.

=head2 get_lot_list

Retrieves a current list of lots.

Scope B<clients>. Typical usage:

    $resp = $client->shop->get_lot_list(
        show_my_lots    => 1,
        itemsonpage     => 25,
        pg              => 2,
    );

Answer will contain a C<lots> field with a list of lots and a C<lots_cnt> pointed to total available items.

More info at L<Shop management: |https://www.reg.com/support/help/api2#shop_get_lot_list>.

=head2 get_category_list

Retrieves a categories/subcategories list. Categories are divided into subcategories.

Scope B<clients>. Typical usage:

    $resp = $client->shop->get_category_list;

Answer will contain a C<category_list> field with a list of categories each of divided into subcategories. Every
subcategory will contain the name and the identiefer.

More info at L<Shop management: get_category_list|https://www.reg.com/support/help/api2#shop_get_category_list>.

=head2 get_suggested_tags

Retrieves a list of buzz tags.

Scope B<clients>. Typical usage:

    $resp = $client->shop->get_suggested_tags(
        limit => 25,
    );

Answer will contain a C<tags> field with a list of popular tags.

More info at L<Shop management: get_suggested_tags|https://www.reg.com/support/help/api2#shop_get_suggested_tags>.

=head1 SEE ALSO

L<Regru::API>

L<Regru::API::Role::Client>

L<REG.API Domain shop management|https://www.reg.com/support/help/api2#shop_functions>

L<REG.API Common error codes|https://www.reg.com/support/help/api2#common_errors>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/regru/regru-api-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Polina Shubina <shubina@reg.ru>

=item *

Anton Gerasimov <a.gerasimov@reg.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by REG.RU LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
