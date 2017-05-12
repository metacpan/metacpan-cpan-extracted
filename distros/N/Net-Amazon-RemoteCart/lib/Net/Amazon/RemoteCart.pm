package Net::Amazon::RemoteCart;
 
use 5.006;


use strict;
use warnings;
#use diagnostics;

use Net::Amazon;
use Net::Amazon::Response;
use Net::Amazon::Request;
###use Data::Dumper; 
use Log::Log4perl qw(:easy);

our $VERSION = '0.02';

use base qw( Net::Amazon );


sub new {
    my($class, %options) = @_;

    if(! exists $options{token}) {
        die "Mandatory parameter 'token' not defined";
    }

    if(! exists $options{affiliate_id}) {
        $options{affiliate_id} = "webservices-20";
    }

    my $self = {
	token => $options{token},
	affiliate_id => $options{affiliate_id},
    };

    # Optional attributes
    $self->{locale}  = $options{locale} if exists $options{locale};
    $self->{cart_id}  = $options{cart_id} if exists $options{cart_id};
    $self->{hmac} = $options{hmac} if $options{hmac};
    $self->{purchase_url} =  $options{purchase_url} if $options{purchase_url};
    
    #Set items only if passed as a hash ref 
    $self->{items} = $options{items} if ref $options{items} eq 'HASH';

    # Set similar_products only if passed as array ref
    $self->{similar_products} = $options{similar_products} if ref $options{similar_products} eq 'ARRAY';

    # Set items only if passed as a hash ref 
    # will hold the raw xmlrefreturned by the latest request
    #$self->{xmlref} = $options{xmlref} if ref $options{xmlref} eq 'HASH'; 

    $self->{f} = 'xml'; # Always the same
    $self->{sims} = 'true'; # Always the same


    $class->SUPER::help_xml_simple_choose_a_parser();

    bless $self, ref($class) || $class; 

    # Make accessors for various params
    for my $attr ( qw( locale cart_id hmac purchase_url similar_products ) ) {
        $class->SUPER::make_accessor($attr);
    }

    return $self;
}



#==========================================================
# synchronize the local instance with Amazon's remote cart
#==========================================================
sub sync {
##    my $self = shift;
    my ($self, %params) = @_;

    if ( exists  $params{cart_id} ) {
	$self->{cart_id} = $params{cart_id};
    }

    if ( exists  $params{hmac} ) {
	$self->{hmac} = $params{hmac};
    }

    if(! exists $self->{cart_id}) {
        die 'Mandatory parameter "cart_id" not defined. $cart->cart_id(mycartid)';
    }

    if(! exists $self->{hmac}) {
        die 'Mandatory parameter "hmac" not defined. $cart->hmac(myhmac)';
    }

    my %req_params;
    $req_params{"Shopping-Cart"} = 'get';

    my $res = $self->_request(\%req_params);
    return $res;
}


#==========================================================
# remove items from cart
#==========================================================
sub remove {
    my ($self, @items) = @_;

    if(! exists $self->{cart_id}) {
        die 'Mandatory parameter "cart_id" not defined. Use $cart->cart_id(mycartid)';
    }

    if(! exists $self->{hmac}) {
        die 'Mandatory parameter "hmac" not defined. Use $cart->hmac(myhmac)';
    }

    my (%params, $remove);

    foreach my $asin (@items ){
	my $item_id = $self->{items}{$asin}{item_id};
	next unless $item_id;
	$params{"Item.$item_id"} = 0;
    }

    $params{ShoppingCart} = 'remove';
    my $res = $self->_request(\%params);

    return $res;
}


#==========================================================
# empty the cart
#==========================================================
sub clear {
    my $self = shift;

    if(! exists $self->{cart_id}) {
        die 'Mandatory parameter "cart_id" not defined. Use $cart->cart_id(mycartid)';
    }

    if(! exists $self->{hmac}) {
        die 'Mandatory parameter "hmac" not defined. Use $cart->hmac(myhmac)';
    }

    my (%params, $remove);

    $params{ShoppingCart} = 'clear';
    my $res = $self->_request(\%params);
	
    return $res;
}




#==========================================================
# change quantities
#==========================================================
sub modify {
    my ($self, %items) = @_;

    unless ( exists $self->{cart_id} && exists $self->{hmac} ){
	die "Cannot modify non-existent cart (i.e. that has no cart_id or hmac)";
    }

    my (@remove_items, %params, $modify, $remove, $res);


    foreach my $asin (keys %items ){
	# If the quantity is set to 0, we'll remove the item
	if ($items{$asin} == 0) {
	    push @remove_items, $asin;
	    $remove = 1;
	
	} elsif  (exists $self->{items}{$asin} ){
	    my $item_id = $self->{items}{$asin}{item_id};
	    $params{"Item.$item_id"} = $items{$asin};
	    $modify = 1;
	}
    }

    if ( $remove ){
	$res = $self->remove(@remove_items);
 	return $res unless $res->status;
    }

    if ( $modify ){
	$params{ShoppingCart} = 'modify';
	$res = $self->_request(\%params);
 	#return $res unless $res->status;
	#$res->status || die "Failed to modify items in cart: ", join(", ", @{$res->messages}), "\n";
    }
    return $res;

}



#===========================================================
# put stuff in the cart
#===========================================================
sub add {
    my ($self, %items) = @_;

    my (%modify_items, %params, $modify, $add, $res);
    

    foreach my $asin (keys %items ){
	# If the item was already in the cart, increase the quantity by the requested num
	if ($self->{items}{$asin} ){
	    $modify_items{$asin} = $items{$asin} + $self->{items}{$asin}{quantity};
	    $modify = 1;
	} else {
	    $params{"Asin.$asin"} = $items{$asin};
	    $add = 1;
	}
    }

    if ( $modify ){
	$res = $self->modify(%modify_items);
 	return $res unless $res->status;
    }

    if ( $add ){

	$params{ShoppingCart} = 'add';
	$res = $self->_request(\%params);
 	return $res unless $res->status;
	#$res->status || die "Failed to add items to cart: ", join(", ", @{$res->messages}), "\n";
    }
	
    return $res;
}




#=================================================
# return an array ref of hashrefs containing
# data about the cart items
#=================================================
sub get_items {
    my $self = shift;
    my @items = values %{$self->{items}};
    return \@items;
}



#===============================================
# First update the cart data from Amzn
# return an array ref of hashrefs containing
# data about the cart items
#===============================================
sub get_items_online {
    my $self = shift;
    $self->sync;
    my @items = values %{$self->{items}};
    return \@items;
}



#=================================================
# Get a hashref of data for a single item 
# based on its ASIN
#=================================================
sub get_item {
    my ($self, $asin) = @_;
    return $self->{items}{$asin};
}





#===========================================================
# calculate the total cost of the items in the cart
#===========================================================
sub total_cost {
    my $self = shift;

    return $self->{total_cost} if exists $self->{total_cost};

    my $items = $self->get_items();
    # Assume it's impossible to have more than one currency in the same cart
    my $currency ;
    my $total = 0;
    foreach ( @{ $items } ){
	my $val;
	($currency, $val) = split /\s+/, $_->{our_price};
	$total += $_->{quantity} * $val;
    }
    
    # format the total val based on currency
    unless ($currency eq 'JPY'){
	$total = sprintf ("%.2f", $total);
    }
    return "$currency $total";
}



#===========================================================
# Get the total cost of the items in the cart, formatted
# for HTML display
#===========================================================
sub total_cost_fmt {
    my $self = shift;

    return $self->{total_cost_fmt} if exists $self->{total_cost_fmt};

    return _price_format($self->total_cost());
}



#==========================================================
# fixes decimals based on currency and changes curency to
# HTML compatible symbol
#==========================================================
sub _price_format {
    my $str = shift;

    return unless defined $str;

    my ($currency, $val) = split /\s+/, $str;

    # format the total val based on currency
    unless ($currency eq 'JPY'){
	$val = sprintf ("%.2f", $val);
    }

    # Format the currency
    if ($currency eq 'USD') {
	$currency = '$';
    } elsif ($currency eq 'GBP'){
	$currency = '&pound';
    } elsif ($currency eq 'EUR'){
	$currency = '&euro';
    } elsif ($currency eq 'JPY'){
	$currency = '&yen';
    } else {
	$currency = "$currency ";
    }

  return "$currency$val";

}




##################################################
# Slightly altered version of the request method in Amazon.pm
sub _request {
##################################################
    my($self, $params) = @_;

    my $url  = URI->new($self->intl_url(Net::Amazon::Request::amzn_xml_url()));

    my $ref;
    my $res = Net::Amazon::Response->new();

    {
       #$params->{locale} = $self->{locale} if $self->{locale};

	# Add the cart_id and hmac if they exist, meaning this isn't the first
	# request for this cart object
	$params->{CartId} = $self->{cart_id} if exists $self->{cart_id};
	$params->{Hmac} = $self->{hmac} if exists $self->{hmac};

	# The f and sims params are always req'd so let's put em in here
	$params->{f} = 'xml';
	$params->{sims} =  'true';

        $url->query_form(
            'dev-t' => $self->{token},
            't'     => $self->{affiliate_id},
            %$params,
        );

        my $urlstr = $url->as_string;

        DEBUG(sub { "URL string [ " . $urlstr . "]" });

        my $xml = $self->fetch_url($urlstr, $res);

        if(!defined $xml) {
            return $res;
        }

        DEBUG(sub { "Received [ " . $xml . "]" });

        my $xs = XML::Simple->new();
        $ref = $xs->XMLin($xml);

        DEBUG(sub { Data::Dumper::Dumper($ref) });

        if(! defined $ref) {
            ERROR("Invalid XML");
            $res->messages( [ "Invalid XML" ]);
            $res->status("");
            return $res;
        }

        if(exists $ref->{ErrorMsg}) {

	    if (ref($ref->{ErrorMsg}) eq "ARRAY") {
	      # multiple errors, set arrary ref
	      $res->messages( $ref->{ErrorMsg} );
	    } else {
	      # single error, create array
	      $res->messages( [ $ref->{ErrorMsg} ] );
            }
            ERROR("Fetch Error: " . $res->message );
            $res->status("");
            return $res;
        }

	# Update the cart data based on the returned xml
	$self->_update_cart_data($ref);

        # We're gonna fall out of this loop here.
    }

    $res->status(1);
    return $res;
}



#=========================================================== 
# reload the data returned from an Amazon request into
# the cart obj 
#===========================================================   
sub _update_cart_data {
    my ($self, $xmlref) = @_;

    $self->{xmlref} = $xmlref;
    $self->{cart_id} = $xmlref->{ShoppingCart}{CartId};
    $self->{hmac} = $xmlref->{ShoppingCart}{HMAC};
    $self->{purchase_url} = $xmlref->{ShoppingCart}{PurchaseUrl};
    $self->{similar_products} = $xmlref->{ShoppingCart}{SimilarProducts}{Product}; #yeah, really

    my $items = {};
    my @items;

    # If there is only one item, {ShoppingCart}{Items}{Item} will be
    # a hash. If more than one, it will be an array ref. We always want
    # an array.
    if ( ref $xmlref->{ShoppingCart}{Items}{Item} eq 'ARRAY' ){ 
	@items = @{ $xmlref->{ShoppingCart}{Items}{Item} };
    }else{
	$items[0] = $xmlref->{ShoppingCart}{Items}{Item};
    }
   
    foreach my $item (@items) {
	my $asin = $item->{Asin} or next;
 
	if ( exists $items->{$asin} ) {
	    $items->{$asin}{quantity} += $item->{Quantity};
	} else {
	    $items->{$asin} = { 
		asin => $item->{Asin}, 
		quantity => $item->{Quantity}, 
		item_id => $item->{ItemId}, 
		product_name => $item->{ProductName}, 
		merchant_sku => $item->{MerchantSku}, # Haven't yet seen this param for real
		list_price => $item->{ListPrice}, 
		list_price_fmt => &_price_format($item->{ListPrice}), 
		our_price => $item->{OurPrice}, 	    
		our_price_fmt => &_price_format($item->{OurPrice}), 	    
	    };
	}
    }
	
    $self->{items} = $items;
    $self->{total_cost} = $self->total_cost();
    $self->{total_cost_fmt} = &_price_format($self->{total_cost});
}



1;

__END__

=head1 NAME

Net::Amazon::RemoteCart - Perl extension for dealing with Amazon.com's 
remote shopping cart API

=head1 SYNOPSIS

    use Net::Amazon::RemoteCart;

    # Start a new cart
    my $cart = Net::Amazon::RemoteCart->new
	( token =>'my_amazon_developer_token' ,
	 affiliate_id =>'my_amazon_assoc_id', 
         );

    # Add some stuff
    my $res = $cart->add( 'myasin' =>1, 'myotherasin'=>4 );

    # See if our request succeeded
    unless ($res->status == 1){
        print "Problem with Amazon request: ", $res->message, "\n";
    }


    # Get data for all cart items
    my $arrayref_of_item_data = $cart->get_items();

    # Get info for a single item based on its ASIN
    my $item = $cart->get_item('myasin');

    # Get the total cost of the items in the cart
    my $total = $cart->total_cost();

    # Maybe save the cart in a session object like CGI::Session
    $session->param("cart", $cart);


    # A later request...

    # Recreate the cart from the one saved in session
    %cart_params = %{ $session->param("cart") };
    my $cart = Net::Amazon::RemoteCart->new(%cart_params);

    # Or instead...
    my $cart = Net::Amazon::RemoteCart->new
	( token =>my_amazon_developer_token ,
	 affiliate_id =>my_amazon_assoc_id,
         cart_id =>mycart_id,
         hmac =>mycart_hmac,
         );
    # update local cart instance by fetching from Amazon
    $res = $cart->sync();


    # Modify quantities
    my $res = $cart->modify('myasin' =>2, 'myotherasin'=>1 );

    # Remove items
    $res = $cart->remove('myasin1', 'myasin2');

    # Get a list similar products (ASINS)
    $arrayref_of_asins = $cart->similar_products();

    # Get the URL for transferring the user and cart
    # over to Amazon for checkout
    $url_string = $cart->purchase_url();


    
=head1 DESCRIPTION

Net::Amazon::RemoteCart, 

RemoteCart is an interface to Amazon Web Services Remote Cart API,
built on Mike Schilli's Net::Amazon package.

RemoteCart attempts to be a consistent and easy to use interface to
the Amazon remote cart API. I've tried to make it work as closely as 
is practical to how someone (Ok, by someone I mean ME) would expect a 
shopping cart to work. It has methods to add, remove, fetch items, 
and modify their quantities based on the product's ASIN. 

Each time a request goes to Amazon's remote cart (i.e. for adding, 
modifying, removing items, or running sync(), etc.), AWS returns the 
data for the whole cart. So the RemoteCart module will update it's own 
representation of the cart each time this happens. Then when you access 
methods like get_items() or purchase_url(), the data is retrieved from 
the local instance of the cart rather than accessing Amazon's server 
every time.

One thing it doesn't do for you is maintain state between requests. 
This can be done either by saving the cart object in a session and 
passing that to new() on the next request, or by saving just the 
cart_id and hmac (returned from Amazon) and passing those to new() and 
then running sync() or get_items_online() to refetch the cart data.

I've also added a couple of convenience methods like total_cost(),
and formatted versions of the prices that I think are useful but 
not provided from Amazon's end.


=head1 METHODS

=over 4


=item new()

Create a new cart instance. Requires that an Amazon developer
token and an Amazon affiliate ID be passed in. See Amazon's 
Web Services page for more info. If you don't yet have an affiliate
ID, you can use "webservices-20" for testing.

    $cart = Net::Amazon::RemoteCart->new
	( token =>my_amazon_developer_token,
	 affiliate_id =>my_amazon_assoc_id, 
         );


=item sync()

Synchronize the local cart's data  with Amazon's 
remote cart data.

Requires that cart_id and hmac be set in the RemoteCart obj
or be passed to this method. If items have been added to the
current cart instance, then the cart_id and hmac will already be set.

    $res = $cart->sync();

or 

    $res = $cart->sync(cart_id=>'my_cart_id', hmac=>'my_cart_hmac');



=item add()

Add one or more items to the remote cart.

Does NOT require that cart_id and hmac be set. If they are not set,
a new remote cart will be created. 

If an item or items that are already in the current cart instance are 
re-added, a separate "modify" request will be generated for those items. 

Running $cart->sync before adding items to an existing remote cart
would be a good idea if you're not sure that you have the latest data
in your current cart instance. Otherwise you can end up with multiple 
versions of the same item in your remote cart, making it difficult to
remove or modify them.   

    $res = $cart->add('asin'=>quantity, 'anotherasin'=>itsquantity);




=item modify()

Modify the quantity of items in the remote cart.

Requires that cart_id and hmac be set. 

If the quantity is set to 0 for one or more items, a separate "remove" 
request will be generated for those items. If an item isn't set in the 
current cart instance, it will be skipped. Running $cart->sync before 
modifying would be a good idea if you're not sure that you have the latest 
data set in your cart instance.  

    $res = $cart->modify('asin'=>newquantity, 'anotherasin'=>itsnewquantity);


=item remove()

Remove items from the remote cart.

Requires that cart_id and hmac be set. If items have been added to the
current cart object, then the cart_id and hmac will already be set.

    $res = $cart->remove('asin1', 'asin2', 'anotherasin');


=item clear()

Clear all items from the remote cart.

Requires that cart_id and hmac be set. If items have been added to the
current cart object, then the cart_id and hmac will already be set.

    $res = $cart->clear();


=item get_items()

Fetch a list of the items in the cart. This gets
the item data from the local current instance of the
cart. To get the item list remotely from Amazon, see get_items_online

    $hashref_of_items = $cart->get_items();


=item get_items_online()

Fetch a list of the items in the cart from Amazon. This gets
the item data remotely from Amazon. To get the item list from the 
local instance of the cart, see get_items

    $hashref_of_items = $cart->get_items_online();


=item get_item()

Fetch data for an individual item in the cart based on ASIN. This gets
the item data from the local current instance of the
cart. To get the item list remotely from Amazon, run $cart->sync() first.

    $hashref_of_item_data = $cart->get_item('myasin');

Here's a Data::Dumper dump of a typical item as returned by get_item() or 
in the list from get_items():


       {
          'asin' => 'B000005QQQ',
          'quantity' => 3,
          'merchant_sku' => undef,
          'list_price' => 'USD 24',
          'list_price_fmt' => '$24.00',
          'our_price' => 'USD 9.6',
          'our_price_fmt' => '$9.60',
          'product_name' => 'Ginsu Knife',
          'item_id' => '9472289293564101475'
        };


=item total_cost()

Returns the total cost of the items in the cart. Uses Amazon's
currency formatting, i.e "USD" or "JPY". It will, correct weirdness
with Amazon's decimal places, so you won't get values like "USD 45.2".
If you want the currency to be an HTML entity, use total_cost_fmt().

    $str = $cart->total_cost();


=item total_cost_fmt()

Returns the total cost of the items in the cart with the currency
as an HTML compatible symbol (i.e. $ for USD or &yen for JPY).

    $str = $cart->total_cost_fmt();


=item hmac()

Get or set the hmac

=item cart_id()

Get or set the cart_id

=item purchase_url()

Get the purchase URL for sending the user to
Amazon's checkout. Accessing this URL will delete the remote cart
from Amazon's system.

=item  similar_products()

Get a list of products similar to those in the cart

=back

=head1 SEE ALSO

L<Net::Amazon>

For more info on Amazon Web Services, see:

L<http://www.amazon.com/gp/browse.html/ref=sws_aws_/002-2831321-1001669?node=3435361>


=head1 INSTALLATION

This module requires the Net::Amazon package, which in turn 
requires Log::Log4perl, LWP::UserAgent, and XML::Simple 2.x

Once all dependencies have been resolved, "Net::Amazon::RemoteCart" installs with
the typical sequence

    perl Makefile.PL
    make
    make test
    make install

LIVE TESTING 
    
(This works the same as for the main Net::Amazon package)
Results returned by Amazon can be incomplete or simply wrong at times,
due to their "best effort" design of the service. This is why the test
suite that comes with this module has been changed to perform its test
cases against canned data. If you want to perform the tests against the
live Amazon servers instead, just set the environment variable

    NET_AMAZON_LIVE_TESTS=1


=head1 CONTACT
    
For questions about Net::amazon in general, the The "Net::Amazon" project's 
home page is hosted on

    http://net-amazon.sourceforge.net

where you can find documentation, news and the latest development and
stable releases for download. If you have questions about how to use
"Net::Amazon", want to report a bug or just participate in its
development, please send a message to the mailing list at

    net-amazon-devel@lists.sourceforge.net

For question, comments, suggestions regarding RemoteCart.pm please send
to either the Net-Amazon mailing list or directly to the author (see below).

=head1 AUTHOR

David Emery, E<lt>demery@skiddlydee.comE<gt>

Thanks to Mike Schilli for helpful comments and advice. Parts of the 
RemoteCart.pm docs were copied from Net::Amazon.



=head1 COPYRIGHT AND LICENSE

Copyright 2004 by David Emery

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 


=cut


