# Nitesi::Cart - Nitesi cart class

package Nitesi::Cart;

use strict;
use warnings;

use constant CART_DEFAULT => 'main';

=head1 NAME 

Nitesi::Cart - Cart class for Nitesi Shop Machine

=head1 DESCRIPTION

Generic cart class for L<Nitesi>.

=head2 CART ITEMS

Each item in the cart has at least the following attributes:

=over 4

=item sku

Unique item identifier.

=item name

Item name.

=item quantity

Item quantity.

=item price

Item price.

=back

=head1 CONSTRUCTOR

=head2 new

=cut

sub new {
    my ($class, $self, %args);

    $class = shift;
    %args = @_;

    my $time = time;

    $self = {error => '', items => [], modifiers => [],
             costs => [], subtotal => 0, total => 0,
             cache_subtotal => 1, cache_total => 1,
             created => $time, last_modified => $time,
    };

    if ($args{name}) {
	$self->{name} = $args{name};
    }
    else {
	$self->{name} = CART_DEFAULT;
    }

    for my $ts (qw/created last_modified/) {
        if (exists $args{$ts}) {
            $self->{$ts} = $args{$ts};
        }
    }

    if ($args{modifiers}) {
	$self->{modifiers} = $args{modifiers};
    }

    if ($args{run_hooks}) {
	$self->{run_hooks} = $args{run_hooks};
    }

    bless $self, $class;

    $self->init(%args);

    return $self;
}

=head2 init

Initializer which receives the constructor arguments, but does nothing.
May be overridden in a subclass.

=cut

sub init {
    return 1;
};

=head1 METHODS

=head2 items

Returns items in the cart.

=cut

sub items {
    my ($self) = shift;

    return $self->{items};
}

=head2 subtotal

Returns subtotal of the cart.

=cut

sub subtotal {
    my ($self) = shift;

    if ($self->{cache_subtotal}) {
	return $self->{subtotal};
    }

    $self->{subtotal} = 0;

    for my $item (@{$self->{items}}) {
	$self->{subtotal} += $item->{price} * $item->{quantity};
    }

    $self->{cache_subtotal} = 1;

    return $self->{subtotal};
}

=head2 total

Returns total of the cart.

=cut

sub total {
    my ($self) = shift;
    my ($subtotal);

    if ($self->{cache_total}) {
	return $self->{total};
    }

    $self->{total} = $subtotal = $self->subtotal();

    # calculate costs
    $self->{total} += $self->_calculate($subtotal);

    $self->{cache_total} = 1;

    return $self->{total};
}
 
=head2 add $item

Add item to the cart. Returns item in case of success.

The item is a hash (reference) which is subject to the following
conditions:

=over 4

=item sku

Item identifier is required.

=item name

Item name is required.

=item quantity

Item quantity is optional and has to be a natural number greater
than zero. Default for quantity is 1.

=item price

Item price is required and a positive number.

Price is required, because you want to maintain the price that was valid at the time of adding to the cart. Should the price in the shop change in the meantime, it will maintain this price. If you would like to update the pages, you have to do it before loading the cart page on your shop.


B<Example:> Add 5 BMX2012 products to the cart

	$cart->add( sku => 'BMX2012', quantity => 5, price => 200);

B<Example:> Add a BMX2012 product to the cart.

	$cart->add( sku => 'BMX2012', price => 200);

=back

=cut

sub add {
    my $self = shift;
    my (%item, $ret);

    if (ref($_[0])) {
	# copy item
	%item = %{$_[0]};
    }
    else {
	%item = @_;
    }

    # run hooks before validating item
    $self->_run_hook('before_cart_add_validate', $self, \%item);

    # validate item
    unless (exists $item{sku} && defined $item{sku} && $item{sku} =~ /\S/) {
	$self->{error} = 'Item added without SKU.';
	return;
    }

    unless (exists $item{name} && defined $item{name} && $item{name} =~ /\S/) {
	$self->{error} = "Item $item{sku} added without a name.";
	return;
    }

    if (exists $item{quantity} && defined $item{quantity}) {
	unless ($item{quantity} =~ /^(\d+)$/ && $item{quantity} > 0) {
	    $self->{error} = "Item $item{sku} added with invalid quantity $item{quantity}.";
	    return;
	}
    }
    else {
	$item{quantity} = 1;
    }

    unless (exists $item{price} && defined $item{price}
	    && $item{price} =~ /^(\d+)(\.\d+)?$/ && $item{price} > 0) {
	$self->{error} = "Item $item{sku} added with invalid price.";
	return;
    }
  
    # run hooks before adding item to cart
    $self->_run_hook('before_cart_add', $self, \%item);

    if (exists $item{error}) {
	# one of the hooks denied the item
	$self->{error} = $item{error};
	return;
    }

    # clear cache flags
    $self->{cache_subtotal} = $self->{cache_total} = 0;

    unless ($ret = $self->_combine(\%item)) {
        push @{$self->{items}}, \%item;
        $self->{last_modified} = time;
    }

    # run hooks after adding item to cart
    $self->_run_hook('after_cart_add', $self, \%item, $ret);

    return \%item;
}

=head2 remove $sku

Remove item from the cart. Takes SKU of item to identify the item.

=cut

sub remove {
    my ($self, $arg) = @_;
    my ($pos, $found, $item);

    $pos = 0;
  
    # run hooks before locating item
    $self->_run_hook('before_cart_remove_validate', $self, $arg);

    for $item (@{$self->{items}}) {
	if ($item->{sku} eq $arg) {
	    $found = 1;
	    last;
	}
	$pos++;
    }

    if ($found) {
	# run hooks before adding item to cart
	$item = $self->{items}->[$pos];

	$self->_run_hook('before_cart_remove', $self, $item);

	if (exists $item->{error}) {
	    # one of the hooks denied removing the item
	    $self->{error} = $item->{error};
	    return;
	}

	# clear cache flags
	$self->{cache_subtotal} = $self->{cache_total} = 0;

	# removing item from our array
	splice(@{$self->{items}}, $pos, 1);

    $self->{last_modified} = time;

	$self->_run_hook('after_cart_remove', $self, $item);
	return 1;
    }

    # item missing
    $self->{error} = "Missing item $arg.";

    return;
}

=head2 update

Update quantity of items in the cart.

Parameters are pairs of SKUs and quantities, e.g.

    $cart->update(9780977920174 => 5,
                  9780596004927 => 3);

Triggers before_cart_update and after_cart_update hooks.

A quantity of zero is equivalent to removing this item,
so in this case the remove hooks will be invoked instead 
of the update hooks.

=cut

sub update {
    my ($self, @args) = @_;
    my ($ref, $sku, $qty, $item, $new_item);

    while (@args > 0) {
	$sku = shift @args;
	$qty = shift @args;

	unless ($item = $self->find($sku)) {
	    die "Item for $sku not found in cart.\n";
	}

	if ($qty == 0) {
	    # remove item instead
            $self->remove($sku);
	    next;
	}

	# jump to next item if quantity stays the same
	next if $qty == $item->{quantity};

	# run hook before updating the cart
	$new_item = {quantity => $qty};

	$self->_run_hook('before_cart_update', $self, $item, $new_item);

	if (exists $new_item->{error}) {
	    # one of the hooks denied the item
	    $self->{error} = $new_item->{error};
	    return;
	}

    $self->{last_modified} = time;

	$self->_run_hook('after_cart_update', $self, $item, $new_item);

	$item->{quantity} = $qty;
    }
}

=head2 clear

Removes all items from the cart.

=cut

sub clear {
    my ($self) = @_;

    # run hook before clearing the cart
    $self->_run_hook('before_cart_clear', $self);
    
    $self->{items} = [];

    # run hook after clearing the cart
    $self->_run_hook('after_cart_clear', $self);

    # reset subtotal/total
    $self->{subtotal} = 0;
    $self->{total} = 0;
    $self->{cache_subtotal} = 1;
    $self->{cache_total} = 1;

    $self->{last_modified} = time;

    return;
}

=head2 find

Searches for an cart item with the given SKU.
Returns cart item in case of sucess.

    if ($item = $cart->find(9780977920174)) {
        print "Quantity: $item->{quantity}.\n";
    }

=cut

sub find {
    my ($self, $sku) = @_;

    for my $cartitem (@{$self->{items}}) {
	if ($sku eq $cartitem->{sku}) {
	    return $cartitem;
        }
    }

    return;
}

=head2 quantity

Returns the sum of the quantity of all items in the shopping cart,
which is commonly used as number of items. If you have 5 apples and 6 pears it will return 11.

    print 'Items in your cart: ', $cart->quantity, "\n";

=cut

sub quantity {
    my $self = shift;
    my $qty = 0;

    for my $item (@{$self->{items}}) {
	$qty += $item->{quantity};
    }

    return $qty;
}

=head2 created

Returns the time (epoch) when the cart was created.

=cut

sub created {
    my ($self) = @_;

    return $self->{created};
}

=head2 last_modified

Returns the time (epoch) when the cart was last modified.

=cut

sub last_modified {
    my ($self) = @_;

    return $self->{last_modified};
}

=head2 count

Returns the number of different items in the shopping cart. If you have 5 apples and 6 pears it will return 2 (2 different items).

=cut

sub count {
    my $self = shift;

    return scalar(@{$self->{items}});
}

=head2 apply_cost 

Apply cost to cart. apply_cost is a generic method typicaly used for taxes, discounts, coupons, gift certificates,...

B<Example:> Absolute cost

	Uses absolute value for amount. Amount 5 is 5 units of currency used (ie. $5).

	$cart->apply_cost(amount => 5, name => 'shipping', label => 'Shipping');

B<Example:> Relative cost

	Uses percentage instead of value for amount. Amount 0.19 in example is 19%.

	relative is a boolean value (0/1).

	$cart->apply_cost(amount => 0.19, name => 'tax', label => 'VAT', relative => 1);

B<Example:> Inclusive cost

	Same as relative cost, but it assumes that tax was included in the subtotal already, and only displays it (19% of subtotal value in example). Inclusive is a boolean value (0/1).

	$cart->apply_cost(amount => 0.19, name => 'tax', label => 'Sales Tax', relative => 1, inclusive => 1);

=cut

sub apply_cost {
    my ($self, %args) = @_;

    push @{$self->{costs}}, \%args;

    unless ($args{inclusive}) {
	# clear cache for total
	$self->{cache_total} = 0;
    }
}

=head2 clear_cost

It removes all the costs previously applied (using apply_cost). Used typically if you have free shipping or something similar, you can clear the costs.

=cut

sub clear_cost {
    my $self = shift;

    $self->{costs} = [];

    $self->{cache_total} = 0;
}

=head2 cost

Returns particular cost by position or by name.

B<Example:> Return tax value by name
	
	$cart->cost('tax'); 

	Returns value of the tax (absolute value in your currency, not percantage)

B<Example:> Return tax value by position

	$cart->cost(0); 

	Returns the cost that was first applied to subtotal. By increasing the number you can retrieve other costs applied.

=cut

sub cost {
    my ($self, $loc) = @_;
    my ($cost, $ret);

    if (defined $loc) {
	if ($loc =~ /^\d+/) {
	    # cost by position
	    $cost = $self->{costs}->[$loc];
	}
	elsif ($loc =~ /\S/) {
	    # cost by name
	    for my $c (@{$self->{costs}}) {
		if ($c->{name} eq $loc) {
		    $cost = $c;
		}
	    }
	}
    }

    if (defined $cost) {
	$ret = $self->_calculate($self->{subtotal}, $cost, 1);
    }

    return $ret;
}

=head2 id

Get or set id of the cart. This can be used for subclasses, 
e.g. primary key value for carts in the database.

=cut

sub id {
    my $self = shift;

    if (@_ > 0) {
	$self->{id} = $_[0];
    }

    return $self->{id};
}

=head2 name

Get or set the name of the cart.

=cut

sub name {
    my $self = shift;

    if (@_ > 0) {
	my $old_name = $self->{name};

	$self->_run_hook('before_cart_rename', $self, $old_name, $_[0]);

	$self->{name} = $_[0];
    $self->{last_modified} = time;

	$self->_run_hook('after_cart_rename', $self, $old_name, $_[0]);
    }

    return $self->{name};
}

=head2 error

Returns last error.

=cut

sub error {
    my $self = shift;

    return $self->{error};
}

=head2 seed $item_ref

Seeds items within the cart from $item_ref.

B<Example:>

	$cart->seed([
		{ sku => 'BMX2015', price => 20, quantity = 1 },
		{ sku => 'KTM2018', price => 400, quantity = 5 },
		{ sku => 'DBF2020', price => 200, quantity = 5 },
	]);

=cut

sub seed {
    my ($self, $item_ref) = @_;

    @{$self->{items}} = @{$item_ref || []};

    # clear cache flags
    $self->{cache_subtotal} = $self->{cache_total} = 0;

    $self->{last_modified} = time;

    return $self->{items};
}

sub _combine {
    my ($self, $item) = @_;

    ITEMS: for my $cartitem (@{$self->{items}}) {
	if ($item->{sku} eq $cartitem->{sku}) {
	    for my $mod (@{$self->{modifiers}}) {
		next ITEMS unless($item->{$mod} eq $cartitem->{$mod});
	    }					
	    			
	    $cartitem->{'quantity'} += $item->{'quantity'};
	    $item->{'quantity'} = $cartitem->{'quantity'};

	    return 1;
	}
    }

    return 0;
}

sub _calculate {
    my ($self, $subtotal, $costs, $display) = @_;
    my ($cost_ref, $sum);

    if (ref $costs eq 'HASH') {
	$cost_ref = [$costs];
    }
    elsif (ref $costs eq 'ARRAY') {
	$cost_ref = $costs;
    }
    else {
	$cost_ref = $self->{costs};
    }

    $sum = 0;

    for my $calc (@$cost_ref) {
	if ($calc->{inclusive} && ! $display) {
	    next;
	}

	if ($calc->{relative}) {
	    $sum += $subtotal * $calc->{amount};
        }
	else {
	    $sum += $calc->{amount};
	}
    }

    return $sum;
}

sub _run_hook {
    my ($self, $name, @args) = @_;
    my $ret;

    if ($self->{run_hooks}) {
	$ret = $self->{run_hooks}->($name, @args);
    }

    return $ret;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
