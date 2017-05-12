######################################################################
package Net::Amazon::Property;
######################################################################
use warnings;
use strict;

use base qw(Net::Amazon);

use Net::Amazon::Property::Book;
use Net::Amazon::Property::CE;
use Net::Amazon::Property::DigitalMusicTrack;
use Net::Amazon::Property::DVD;
use Net::Amazon::Property::Music;
use Net::Amazon::Property::Software;
use Net::Amazon::Property::VideoGames;
use Net::Amazon::Attribute::ReviewSet;
use Data::Dumper;
use Log::Log4perl qw(:easy);

# read: a poor man's XPath
# NOTE: Igor Sutton Lopes has a module called Hash::Path that does exactly
# what I am doing here.  He beat me to the punch. :)
our %DEFAULT_ATTRIBUTES_XPATH = (
    Availability => [qw(Offers Offer OfferListing Availability)],
    Catalog => [qw(ItemAttributes ProductGroup)],
    Binding => [qw(ItemAttributes Binding)],
    CollectibleCount => [qw(OfferSummary TotalCollectible)],
    CollectiblePrice => [qw(OfferSummary LowestCollectiblePrice FormattedPrice)],
    ImageUrlLarge => [qw(LargeImage URL)],
    LargeImageUrl => [qw(LargeImage URL)],
    LargeImageWidth => [qw(LargeImage Width content)],
    LargeImageHeight => [qw(LargeImage Height content)],
    ListPrice => [qw(ItemAttributes ListPrice FormattedPrice)],
    Manufacturer => [qw(ItemAttributes Manufacturer)],
    MediumImageUrl => [qw(MediumImage URL)],
    ImageUrlMedium => [qw(MediumImage URL)],
    MediumImageWidth => [qw(MediumImage Width content)],
    MediumImageHeight => [qw(MediumImage Height content)],
    OurPrice => [qw(Offers Offer OfferListing Price FormattedPrice)],
    ImageUrlSmall => [qw(SmallImage URL)],
    SmallImageUrl => [qw(SmallImage URL)],
    SmallImageWidth => [qw(SmallImage Width content)],
    SmallImageHeight => [qw(SmallImage Height content)],
    SuperSaverShipping => [qw(Offers Offer OfferListing IsEligibleForSuperSaverShipping)],
    Title => [qw(ItemAttributes Title)],
    title => [qw(ItemAttributes Title)],
    ThirdPartyNewCount => [qw(OfferSummary TotalNew)],
    ThirdPartyNewPrice => [qw(OfferSummary LowestNewPrice FormattedPrice)],
    TotalOffers => [qw(Offers TotalOffers)],
    UsedCount => [qw(OfferSummary TotalUsed)],
    UsedPrice => [qw(OfferSummary LowestUsedPrice FormattedPrice)],
    RawListPrice => [qw(ItemAttributes ListPrice Amount)],
    CurrencyCode => [qw(ItemAttributes ListPrice CurrencyCode)],
    ReleaseDate => [qw(ItemAttributes ReleaseDate)],
    SimilarProducts => [qw(SimilarProducts SimilarProduct)],
);

our @DEFAULT_ATTRIBUTES = qw(
  SalesRank ASIN DetailPageURL ProductDescription
  NumMedia NumberOfOfferings
);

our %COMPATIBLE_ATTRIBUTES = (
	'Asin'        => 'ASIN',
	'url'         => 'DetailPageURL',
    'Media'       => 'Binding',
    'ProductName' => 'title',
);

__PACKAGE__->make_accessor($_) for @DEFAULT_ATTRIBUTES;
__PACKAGE__->make_accessor($_) for keys %DEFAULT_ATTRIBUTES_XPATH;
__PACKAGE__->make_accessor($_) for qw(year review_set image_set offer_set);
__PACKAGE__->make_array_accessor($_) for qw(browse_nodes similar_asins);
__PACKAGE__->make_compatible_accessor($_, $COMPATIBLE_ATTRIBUTES{$_}) for keys %COMPATIBLE_ATTRIBUTES;

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    if(!$options{xmlref}) {
        die "Mandatory param xmlref missing";
    }

    my $self = { 
        %options, 
    };

    bless $self, $class;

        # Set default attributes
    for my $attr (@DEFAULT_ATTRIBUTES) {
        $self->$attr($options{xmlref}->{$attr});
    }

    for my $attr (keys %DEFAULT_ATTRIBUTES_XPATH) {
        my $value = __PACKAGE__->walk_hash_ref($options{xmlref}, $DEFAULT_ATTRIBUTES_XPATH{$attr});
        $self->$attr($value);
    }

    if (defined $options{xmlref}->{OfferSummary}) {
        $self->NumberOfOfferings($self->UsedCount() + $self->ThirdPartyNewCount() + $self->CollectibleCount());
    }
    if (defined $options{xmlref}->{EditorialReviews}) {
        $self->ProductDescription($options{xmlref}->{EditorialReviews}->{EditorialReview}->[0]->{Content});
    }

    my @browse_nodes;
    if (ref $options{xmlref}->{BrowseNodes}->{BrowseNode} eq 'ARRAY') {
        for my $bn (@{$options{xmlref}->{BrowseNodes}->{BrowseNode}}) {
            push @browse_nodes, $bn->{Name};     

            # Walk the BrowseNode Ancestors and collect the other BrowseNode Ids
            for (my $ref = $bn->{Ancestors}->{BrowseNode}; defined $ref; $ref = $ref->{Ancestors}->{BrowseNode}) {    
                # The BrowseNodeId is also available...
                push @browse_nodes, $ref->{Name} if defined($ref->{Name});
            }
        }
    }
    $self->browse_nodes(\@browse_nodes);

    my @similars;
    for my $similar (@{$options{xmlref}->{SimilarProducts}->{SimilarProduct}}) {
        # You could also capture the Title as well...
        push @similars, $similar->{ASIN};
    }
    $self->similar_asins(\@similars); 
    
    return $self;
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    my $result = "\"" . $self->Title . "\", ";

    if($self->{xmlref}->{Manufacturer}) {
        $result .= "$self->{xmlref}->{Manufacturer}, ";
    }

    $result .= $self->year() . ", " if $self->year();

    $result .= $self->_best_effort_price() . ", ";
    $result .= $self->ASIN();

    return $result;
}

##################################################
sub _best_effort_price {
##################################################
    my($self) = @_;

    my $price;
    if ($self->OurPrice()) {
        $price = $self->OurPrice();
    } elsif ($self->ThirdPartyNewPrice()) {
        $price = $self->ThirdPartyNewPrice();
    } elsif ($self->UsedPrice()) {
        $price = $self->UsedPrice();
    } else {
        $price = '[$unknown]';
    }

    return $price;
}


##################################################
sub factory {
##################################################
    my(%options) = @_;

    my $xmlref = $options{xmlref};
    die "Called factory without xmlref" unless $xmlref;

    #DEBUG(sub {"factory xmlref=" . Data::Dumper::Dumper($xmlref)});

    my $catalog = $xmlref->{ItemAttributes}->{ProductGroup};
    my $obj;

    if(0) {
    } elsif($catalog eq "Book" || $catalog eq "eBooks") {
        DEBUG("Creating new Book Property");
        $obj = Net::Amazon::Property::Book->new(xmlref => $xmlref);
    } elsif($catalog eq "Music") {
        DEBUG("Creating new Music Property");
        $obj = Net::Amazon::Property::Music->new(xmlref => $xmlref);
    } elsif($catalog eq "DVD") {
        DEBUG("Creating new DVD Property");
        $obj = Net::Amazon::Property::DVD->new(xmlref => $xmlref);
    } elsif($catalog eq "Software") {
        DEBUG("Creating new Software Property");
        $obj = Net::Amazon::Property::Software->new(xmlref => $xmlref);
    } elsif($catalog eq "Video Games") {
        DEBUG("Creating new Video Games Property");
        $obj = Net::Amazon::Property::VideoGames->new(xmlref => $xmlref);
    } elsif($catalog eq "CE") { # Consumer Electronics?
        DEBUG("Creating new CE Property");
        $obj = Net::Amazon::Property::CE->new(xmlref => $xmlref);
    } elsif($catalog eq "Digital Music Track") {
	DEBUG("Creating new Digital Music Track");
	$obj = Net::Amazon::Property::DigitalMusicTrack->new(xmlref => $xmlref);
    } else {
#         print "UNKNOWN CATALOG: ", Data::Dumper::Dumper($xmlref), "\n";
#         die "%Error: there is no property defined for type '$catalog'\n";
        DEBUG("Creating new Default Property ($catalog)");
        $obj = Net::Amazon::Property->new(xmlref => $xmlref);
    }

    return $obj;
}

##################################################
sub init_via_xmlref {
##################################################
    my($self, $xmlref) = @_;

    my $reviewset = Net::Amazon::Attribute::ReviewSet->new();

    if(exists $xmlref->{CustomerReviews}) {
        $reviewset->init_via_xmlref($xmlref->{CustomerReviews});
    }

    $self->review_set($reviewset); 
}


##################################################
##################################################


##################################################

1;

__END__

=head1 NAME

Net::Amazon::Property - Baseclass for products on amazon.com

=head1 SYNOPSIS

  use Net::Amazon;

  # ...

  if($resp->is_success()) {
      for my $prop ($resp->properties) {
          print $_->ProductName(), " ",
                $_->Manufacturer(), " ",
                $_->OurPrice(), "\n";

=head1 DESCRIPTION

C<Net::Amazon::Property> is the baseclass for results returned
from Amazon web service queries. The term 'properties' is used as 
a generic description for an item on amazon.com.

Typically, the C<properties()> method of a C<Net::Amazon::Response::*> object
will return one or more objects of class C<Net::Amazon::Property> or
one of its subclasses, e.g. C<Net::Amazon::Property::Book> or
C<Net::Amazon::Property::CD>.

While C<Net::Amazon::Property> objects expose accessors for all 
fields returned in the XML response (like C<OurPrice()>, C<ListPrice()>,
C<Manufacturer()>, C<Asin()>, C<Catalog()>, C<ProductName()>, subclasses
might define their own accessors to more class-specific fields
(like the iC<Net::Amazon::Property::Book>'s C<authors()> method returning
a list of authors, while C<Net::Amazon::Property>'s C<Authors()> method
will return a reference to a sub-hash containing a C<Author> field, just like
the response's XML contained it).

=head2 METHODS

Methods vary, depending on the item returned from a query. Here's the most
common ones. They're all accessors, meaning they can be used like C<Method()>
to retrieve the value or like C<Method($value)> to set the value of the
field.

=over 4

=item Asin()

The item's ASIN number.  This option is deprecated, please use ASIN.

=item ASIN()

The item's ASIN number.

=item ProductName()

Book title, CD album name or item name.  This option is actually an alias for
the method title, and is actually dependent upon the type of item returned.

=item Availability()

Text string describing if the item is available. Examples:
C<"Usually ships within 24 hours"> or
C<"Out of Print--Limited Availability">.

=item Catalog()

Shows the catalog the item was found in: C<Book>, C<Music>, C<Classical>,
C<Electronics> etc.

=item Authors()

Returns a sub-hash with a C<Author> key, which points to either a single
$scalar or to a reference of an array containing author names as scalars.

=item ReleaseDate()

Item's release date, format is "NN Monthname, Year".

=item Manufacturer()

Music label, publishing company or manufacturer

=item ImageUrlSmall()

URL to a small (thumbnail) image of the item

=item ImageUrlMedium()

URL to a medium-size image of the item

=item ImageUrlLarge()

URL to a large image of the item

=item ListPrice()

List price of the item

=item OurPrice()

Amazon price of the item

=item UsedPrice()

Used price of the item

=item RawListPrice()

Unformatted list price as an integer, without currency symbol.

=item CurrencyCode()

The currency code for the L</ListPrice()>, e.g. C<USD>.

=item SalesRank()

Sales rank of the item (contains digits and commas, like 1,000,001)

=item Media()

Type of media (Paperback, etc.).

=item NumMedia()

Number of media the item carries (1,2 CDs etc.).

=item ProductDescription()

Lengthy textual description of the product.

=item CollectiblePrice() 

Lowest price in "Collectible" category.

=item CollectibleCount()

Number of offerings in "Collectible" category.

=item NumberOfOfferings()

Total number of offerings in all categories.

=item UsedCount()

Number of offerings in "Used" category.

=item TotalOffers()

Number of offerings of the product.

=item ThirdPartyNewPrice()

Lowest price in "Third Party New" category.

=item ThirdPartyNewCount()

Number of offerings in "Third Party New" category.

=item SmallImageWidth()

Return the width of the small image in pixels.

=item SmallImageHeight()

Return the height of the small image in pixels.

=item MediumImageWidth()

Return the width of the medium image in pixels.

=item MediumImageHeight()

Return the height of the medium image in pixels.

=item LargeImageWidth()

Return the width of the large image in pixels.

=item LargeImageHeight()

Return the height of the large image in pixels.

=item SuperSaverShipping()

Boolean value that indicates if the product is eligible for super saver
shipping.

=item year()

The release year extracted from ReleaseDate().

=item browse_nodes()

Returns a list of browse nodes (text string categories) for this item.

=item similar_asins()

Returns a list of ASINs of similar items for this item.

=item SimilarProducts()

Returns a list of ASINs and titles of similar items for this item.

=back

Please check the subclasses of C<Net::Amazon::Property> for specialized 
methods.

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
