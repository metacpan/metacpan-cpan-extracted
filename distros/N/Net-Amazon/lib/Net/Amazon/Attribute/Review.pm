######################################################################
package Net::Amazon::Attribute::Review;
######################################################################
use warnings;
use strict;
use Log::Log4perl qw(:easy);
use base qw(Net::Amazon);

__PACKAGE__->make_accessor($_) for qw(date asin rating summary content 
                                      total_votes helpful_votes customer_id
				      customer_name customer_location);

use constant ELEMENT_TO_METHOD_MAP => {
    # XXX: should ASIN be Asin, ASIN, or asin?
    'ASIN'         => 'asin',
    'Content'      => 'content',
    'CustomerId'   => 'customer_id',
    'CustomerLocation' => 'customer_location',
    'CustomerName' => 'customer_name',
    'Date'         => 'date',
    'HelpfulVotes' => 'helpful_votes',
    'Rating'       => 'rating',
    'Summary'      => 'summary',
    'TotalVotes'   => 'total_votes',
};

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    my $self = {
        rating  => "",
        summary => "",
        content => "",
        helpful_votes => "",
        customer_id => "",
        customer_name => "",
        customer_location => "",
        asin => "",
        date => "",
        total_votes => "",
        %options,
    };

    bless $self, $class;
}

##################################################
sub init_via_xmlref {
##################################################
    my($self, $xmlref) = @_;

    my $href = (ELEMENT_TO_METHOD_MAP);

    for(keys %$href) {
        my $method = lc($href->{$_});
        if(defined $xmlref->{$_}) {
            $self->$method($xmlref->{$_});
        } 
    }

    $self->customer_location($xmlref->{Reviewer}{Location});
    $self->customer_name($xmlref->{Reviewer}{Name});
}

1;

__END__

=head1 NAME

Net::Amazon::Attribute::Review - Customer Review Class

=head1 SYNOPSIS

    use Net::Amazon::Attribute::Review;
    my $rev = Net::Amazon::Attribute::Review->new(
                 'rating'        => $rating,
                 'summary'       => $summary,
                 'content'       => $content,
                 'asin'          => $asin,
                 'customer_id'   => $customer_id,
                 'date'          => $date,
                 'helpful_votes' => $helpful_votes,
                 'total_votes'   => $total_votes,
    );

=head1 DESCRIPTION

C<Net::Amazon::Attribute::Review> holds customer reviews.

=head2 METHODS

=over 4

=item rating()

Accessor for the numeric value of the rating.

=item summary()

Accessor for the string value of the summary.

=item content()

Accessor for the string value of the content.

=item asin()

Accessor for the string value of ASIN.

=item customer_id()

Accessor for the string value of the customer ID.

=item customer_location()

Accessor for the string value of the customer location.

=item customer_name()

Accessor for the string value of the customer name.

=item helpful_votes()

Accessor for the numeric value of the helpful votes.

=item total_votes()

Accessor for the numeric value of the total votes.

=back

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

__END__
<Review>
  <ASIN>0201360683</ASIN>
  <Rating>4</Rating>
  <HelpfulVotes>2</HelpfulVotes>
  <CustomerId>YYYYYYYXXYYYY</CustomerId>
  <Reviewer>
    <CustomerId>YYYYYYYXXYYYY</CustomerId>
    <Name>John Doe</Name>
    <Nickname>JD</Nickname>
    <Location>New York, NY USA</Location>
  </Reviewer>
  <TotalVotes>2</TotalVotes>
  <Date>2000-03-09</Date>
  <Summary>Wicked Pisser!</Summary>
  <Content>I found this book to be very good</Content>
</Review>
