######################################################################
package Net::Amazon::Attribute::ReviewSet;
######################################################################
use warnings;
use strict;
use Log::Log4perl qw(:easy);
use Net::Amazon::Attribute::Review;
use base qw(Net::Amazon);

__PACKAGE__->make_accessor($_) for qw(average_customer_rating total_reviews 
                                      total_review_pages);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    my $self = {
        reviews => [],  # list of reviews
    };

    bless $self, $class;
}

###########################################
sub add_review {
###########################################
    my($self, $review) = @_;

    if(ref $review ne "Net::Amazon::Attribute::Review") {
        warn "add_review called with type ", ref $review;
        return undef;
    }

    push @{$self->{reviews}}, $review;
}

###########################################
sub reviews {
###########################################
    my($self) = @_;

    return @{$self->{reviews}};
}

##################################################
sub init_via_xmlref {
##################################################
    my($self, $xmlref) = @_;

    my @pairs = qw(AverageRating    average_customer_rating
                   TotalReviews     total_reviews
                   TotalReviewPages total_review_pages);

    while(my($field, $method) = splice @pairs, 0, 2) {
        
        if(exists $xmlref->{$field}) {
            DEBUG "Setting $field via $method to $xmlref->{$field}";
            $self->$method($xmlref->{$field});
        } 
    }

    for my $review_xmlref (@{$xmlref->{Review}}) {
        my $review = Net::Amazon::Attribute::Review->new();
        $review->init_via_xmlref($review_xmlref);
        DEBUG "Adding review ", $review->summary();
        $self->add_review($review);
    }
}

1;

__END__

=head1 NAME

Net::Amazon::Attribute::ReviewSet - A set of customer reviews

=head1 SYNOPSIS

    use Net::Amazon::Attribute::ReviewSet;
    my $rev = Net::Amazon::Attribute::Review->new(
        average_customer_rating => $avg,
        total_reviews  => $total,
        );

=head1 DESCRIPTION

C<Net::Amazon::Attribute::ReviewSet> holds a list of customer
reviews, each of type C<Net::Amazon::Attribute::Review>.

=head2 METHODS

=over 4

=item C<< $self->reviews() >>

Returns a list of C<Net::Amazon::Attribute::Review> objects.

=item C<< $self->average_customer_rating() >>

Accessor for the average customer rating, a numeric value.

=item C<< $self->total_reviews() >>

Accessor for the total number of reviews. Please note that this
might not be equal to the number of reviews held in the list, since
there might be less customer reviews than total reviews (reviews
can also be non-customer-reviews, but they're not available by
the web service as of Aug 2003).

=item C<< $self->total_review_pages >>

Accessor for the total number of review pages.

=item C<< $self->add_review($rev) >>

Add a C<Net::Amazon::Attribute::Review> object to the list.
(Used internally only).

=back

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
