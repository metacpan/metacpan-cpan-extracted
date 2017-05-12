package Nitesi::Inventory;

use strict;
use warnings;

use Moo::Role;
use Sub::Quote;

=head1 NAME

Nitesi::Inventory - Inventory class for Nitesi Shop Machine

=head1 ATTRIBUTES

=head2 quantity

Number of available products.

=cut

has quantity => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return 0;},
);

=head2 in_stock

Whether to show product as in stock or not.

=cut

has in_stock => (
    is => 'rw',
);

=head1 METHODS

=head2 inventory_api_info

API information for inventory class.

=cut

sub inventory_api_info {
    my $self = shift;

    return {table => 'inventory',
            key => 'sku',
            sparse => 1,
    };
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
