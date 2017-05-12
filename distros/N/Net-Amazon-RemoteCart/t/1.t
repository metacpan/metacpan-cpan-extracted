# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use warnings;
use strict;

use Test::More tests => 10;

BEGIN { 
    #chdir 't' if -d 't';
    use lib "./lib";
    use_ok('Net::Amazon::RemoteCart') 
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Net::Amazon::RemoteCart;
use File::Spec;
#use Data::Dumper;

my $CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned") unless -d $CANNED;

if(! exists $ENV{NET_AMAZON_LIVE_TESTS}) {
    for(map { File::Spec->catfile($CANNED, $_) }
        qw(add.xml  add_error.xml  modify.xml  remove.xml clear.xml)
	) {
        open FILE, "<$_" or die "Cannot open $_";
        my $data = join '', <FILE>;
        close FILE;
        push @Net::Amazon::CANNED_RESPONSES, $data;
    }
}

######################################################################
# Successful item add
######################################################################
my $cart = Net::Amazon::RemoteCart->new(
    	token       => 'D1QS8OZAEP31QW',
	affiliate_id =>'webservices-20',
);


# Add items
my $resp = $cart->add( 'B000002WU5' =>1, 'B00000IP2Z'=>3 );

#print "RES: ", Dumper($resp), "\n";

ok($resp->is_success(), "Successful addition of items");


#print "XMLref: ", Dumper($cart->{xmlref}), "\n";

######################################################################
# Error adding item
######################################################################

# Add items
$resp = $cart->add( 'NOSUCHITEM' =>1 );


ok($resp->is_error(), "Error reported correctly");
like($resp->message(), qr/(unavailable)|(unable)/, "Unavailable or incorrect ASIN reported correctly");

######################################################################
# Successful item modify
######################################################################

$resp = $cart->modify( 'B000002WU5' =>2, 'B00000IP2Z'=>2 );
ok($resp->is_success(), "Successful modification of items");


######################################################################
# Successful item get
######################################################################

my $item1 = $cart->get_item('B000002WU5');

like ($item1->{product_name}, qr/Cabaret/, "Correctly got item title");


######################################################################
# Successful item remove
######################################################################

$resp = $cart->remove( 'B000002WU5' );
ok($resp->is_success(), "Successful removal of item");


my $itemlist = $cart->get_items();

ok(scalar ( @{$itemlist} ) == 1, "One item left in cart - as it should be...");


######################################################################
# Successful get purchase_url
######################################################################


my $purchase_url = $cart->purchase_url();


like( $purchase_url, qr|http://www\.amazon\.[\w\./]+/shopping-basket|, "Correctly got purchase_url");


######################################################################
# Successful clear
######################################################################

$resp = $cart->clear( );
ok($resp->is_success(), "Successful cart clearing");

