#############################################
package Net::Amazon::Response::Seller;
#############################################
use base qw(Net::Amazon::Response);

use Net::Amazon::Result::Seller;
use Data::Dumper;
use Log::Log4perl qw(:easy);

##############################
sub new {
##############################
    my($class, %options) = @_;
   
    my $self = $class->SUPER::new(%options);
    bless $self, $class;   # reconsecrate
}

##################################################
sub result {
##################################################
    my($self) = @_;

    if($self->is_success()) {
        DEBUG "Calling Seller constructor with ", Dumper($self);
        return Net::Amazon::Result::Seller->new(
            xmlref => $self->{xmlref}->{SellerListings},
        );
    }

    return undef;
}

##################################################
sub properties {
##################################################
    my($self) = @_;

    die "properties() not defined in ", __PACKAGE__, ". Use result() instead";
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    return $self->result()->as_string();
}

##################################################
sub xmlref_add {
##################################################
    my($self, $xmlref) = @_;

    my $nof_items_added = 0;

    DEBUG("xmlref_add (before):", Data::Dumper::Dumper($xmlref));

    unless(ref($self->{xmlref}) eq "HASH" &&
        ref($self->{xmlref}->{SellerListings}) eq "ARRAY") {
        $self->{xmlref}->{SellerListings} = [];
    }

    if(ref($xmlref->{SellerListings}->{SellerListing}) eq "ARRAY") {
            # Is it an array of items?
        push @{$self->{xmlref}->{SellerListings}},
             $_ for @{$xmlref->{SellerListings}->{SellerListing}};

        $nof_items_added = scalar @{$xmlref->{SellerListings}->{SellerListing}};
    } else {
            # It is a single item
        push @{$self->{xmlref}->{SellerListings}},
             $xmlref->{SellerListings}->{SellerListing};
        $nof_items_added = 1;
    }

    #DEBUG("(Seller) xmlref_add (after):", Data::Dumper::Dumper($self));
    return $nof_items_added;
} 

1;
