use warnings;
use strict;

package Search::Lemur::Result;


=head1 NAME

Lemur::Result

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.00';


=head1 DESCRIPTION

Stores the results from a lemur query for a single term.
   
=cut

=head2 Main Methods

=over 2
=cut

# create a new result object.  This should only be called by a
# Lemur object, in its query method.  One of these will be created 
# for every result returned by the query.  
# 
# The arguments are query term, the document ID, document length, 
# and term frequency.
#
# If these arguments are not given, this will return undef
sub _new {
    my $class = shift;
    my $self = {};
    if (scalar(@_) >= 3) {
        my ($term, $ctf, $df) = @_;
        $self = { term => $term,
                 ctf => $ctf,
                 df => $df,
                 lines => [] };
    } else { return undef; }
    bless $self, $class;
    return $self;
}

=item ctf

Get the corpus term frequency for this result.

=cut

sub ctf {
    my $self = shift;
    return $self->{ctf};
}


=item term

Get the query term for this result.  

Returns the number of times this term occured in the corpus.

=cut

sub term {
    my $self = shift;
    return $self->{term};
}

=item df

Get the document frequency for this result.

Returns the number of documents this term occurred in.

=cut

sub df {
    my $self = shift;
    return $self->{df};
}


=item docs

Get the array of documents returned by this query.

Returns an array of resultItem objects.

=cut

sub docs {
    my $self = shift;
    return $self->{lines};
}

# _add(resultItem)
#
# add a resultItem to the list
#
# This should only be called by Lemur objects' _parse method when
# populating the result
sub _add {
    my $self = shift;
    my $line = shift;
    push @{$self->{lines}}, $line;
}

=item equals

Test equality between this result and the given one (used mostly for
testing).

=cut


sub equals {
    my $self = shift;
    my $other = shift;
    return 0 unless ($other->isa('Search::Lemur::Result'));
    my $numlines = scalar(@{$self->{lines}});
    return 0 unless ($numlines == @{$other->{lines}});
    # check that the resultItems are all the same (order matters)
    for (my $i = 0; $i < $numlines; $i++){
        return 0 unless (${$self->{lines}}[$i]->equals(
                    ${$self->{lines}}[$i]));
    }
    return ($self->{term} eq $other->{term}) &&
           ($self->{ctf} == $other->{ctf}) &&
           ($self->{df} == $other->{df});
}
    

=back

=head1 AUTHOR

Patrick Kaeding, C<< <pkaeding at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-search-lemur at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Lemur>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Lemur

    You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Lemur>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Lemur>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Lemur>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Lemur>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Patrick Kaeding, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; 
