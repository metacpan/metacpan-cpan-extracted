######################################################################
package Net::Amazon::Result::Seller;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon);

use Data::Dumper;
use Log::Log4perl qw(:easy);
use Net::Amazon::Result::Seller::Listing;

our @DEFAULT_ATTRIBUTES = qw(StoreName SellerNickname 
                             NumberOfOpenListings StoreId SellerId);
__PACKAGE__->make_accessor($_) for @DEFAULT_ATTRIBUTES;
__PACKAGE__->make_array_accessor($_) for qw(listings);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    if(!$options{xmlref}) {
        die "Mandatory param xmlref missing";
    }

    my @listings = ();

    my $self = { 
        %options, 
               };

    bless $self, $class;

    my $ref = $options{xmlref};

    $self->StoreName($ref->[0]->{Seller}->{Nickname});
    $self->SellerNickname($ref->[0]->{Seller}->{Nickname});
    $self->SellerId($ref->[0]->{Seller}->{SellerId});
    $self->StoreId($ref->[0]->{Seller}->{SellerId});
    $self->NumberOfOpenListings(scalar(@$ref));

    for my $listing (@$ref) {
        push @listings, 
             Net::Amazon::Result::Seller::Listing->new(
                 xmlref => $listing);
    }

    $self->listings(\@listings);

    return $self;
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    my $result = $self->StoreName() . 
                 " (" .
                 $self->SellerNickname() .
                 "): " .
                 $self->NumberOfOpenListings() .
                 "";

    return $result;
}

1;

__END__

=head1 NAME

Net::Amazon::Result::Seller - Class for Seller info

=head1 SYNOPSIS

  use Net::Amazon;

  # ...

  if($resp->is_success()) {
      print $resp->result()->as_string();
  }

=head1 DESCRIPTION

C<Net::Amazon::Result::Seller> is a container for results on a seller 
search. It contains data on one particular seller (the one turned up by
the previous search) and the listings this seller is currently running.

=head2 METHODS

=over 4

=item StoreName()

Name of the seller's store.

=item SellerNickname()

Seller's nickname.

=item StoreId()

ID of seller's store.

=item NumberOfOpenListings()

Number of listings the seller has currently open.

=item listings()

Returns an array of C<Net::Amazon::Result::Seller::Listing> objects.
See the documentation of this class for details.

=back

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
