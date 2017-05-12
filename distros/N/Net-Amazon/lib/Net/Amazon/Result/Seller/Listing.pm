######################################################################
package Net::Amazon::Result::Seller::Listing;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon);

use Data::Dumper;
use Log::Log4perl qw(:easy);

# Tracking the different functions between AWS3 and AWS4.
# ExchangeConditionType -> ExchangeCondition
# ExchangeSellerRating -> ???
# ExchangeQuantityAllocated  -> ExchangeQuantity
# ExchangeSellerCountry -> ???
# ExchangeSellerState -> ???
# ExchangeFeaturedCategory -> ???
# ExchangeAvailability -> ???
# ExchangeOfferingType -> ??? 
# ??? -> ExchangeSubCondition 
# ExchangeDescription -> ???


our %DEFAULT_ATTRIBUTES_XPATH = (
    ExchangeStartDate    => [qw(StartDate)],
    ExchangeEndDate      => [qw(EndDate)],
    ExchangeAsin         => [qw(ASIN)],
    ExchangeTitle        => [qw(Title)],
    ListingId            => [qw(ListingId)],
    ExchangeId           => [qw(ExchangeId)],
    ExchangeQuantityAllocated => [qw(Quantity)],
    ExchangeQuantity     => [qw(Quantity)],
    ExchangeCondition    => [qw(Condition)],
    ExchangeConditionType=> [qw(SubCondition)],
    ExchangeSubCondition => [qw(SubCondition)],
    ExchangeStatus       => [qw(Status)],
    ExchangePrice        => [qw(Price FormattedPrice)],
    ExchangeCurrencyCode => [qw(Price CurrencyCode)],
    ExchangeAmount       => [qw(Price Amount)],
    ExchangeSellerId     => [qw(Seller SellerId)],
    ExchangeSellerNickname => [qw(Seller Nickname)],
);

__PACKAGE__->make_accessor($_) for keys %DEFAULT_ATTRIBUTES_XPATH;

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

    DEBUG "Calling Listing with xmlref=", Dumper($options{xmlref});

    for my $attr (keys %DEFAULT_ATTRIBUTES_XPATH) {
        my $value = __PACKAGE__->walk_hash_ref($options{xmlref}, $DEFAULT_ATTRIBUTES_XPATH{$attr});
        $self->$attr($value);
    }

    return $self;
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    my $result = 
                 $self->ExchangeTitle() .
                 " (" .
                 $self->ExchangeAsin() . 
                 "): " .
                 $self->ExchangePrice() .
                 "";

    return $result;
}

1;

__END__

=head1 NAME

Net::Amazon::Result::Seller::Listing - Class for a single Listing of a Seller

=head1 SYNOPSIS

  for($seller_search_resp->result()->seller()->listings()) {
      print $_->as_string(), "\n";
  }

=head1 DESCRIPTION

C<Net::Amazon::Result::Seller::Listing> is a container for a single listing
owned by a third-party seller, who is represented by a
C<Net::Amazon::Result::Seller> object.

An object of this class is also returned by an C<Exchange> request, using
C<Net::Amazon::Response::Exchange>'s C<result> method.

=head2 METHODS

=over 4

=item ExchangeStartDate()

=item ExchangeConditionType()

=item ExchangeCondition()

=item ExchangeSubCondition()

=item ExchangeAsin()

=item ExchangeSellerId()

=item ExchangeEndDate()

=item ExchangePrice()

=item ExchangeAmount()

=item ExchangeCurrencyCode()

=item ExchangeStatus()

=item ExchangeId()

=item ExchangeTitle()

=item ExchangeQuantityAllocated()

=item ExchangeQuantity()

=item ExchangeSellerNickname()

=item ListingId()

=back

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
