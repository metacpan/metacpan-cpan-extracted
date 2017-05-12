use warnings;
use strict;

use Data::Dumper;

package Search::Lemur::ResultItem;


=head1 NAME

Lemur::ResultItem

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.00';

=head1 DESCRIPTION

   
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
# If these arguments are not given, this will die.
sub _new {
    my $class = shift;
    my $self = {};
    if (scalar(@_) == 3) {
        my ($docid, $doclen, $tf) = @_;
        $self = { docid => $docid,
                 doclen => $doclen,
                 tf => $tf };
    } else { die "Not enough arguments to create a resultItem object."; }
    bless $self, $class;
    return $self;
}

=item docid

Get the document ID value for this result.

=cut

sub docid {
    my $self = shift;
    if (@_) { $self->{url} = shift; }
    return $self->{docid};
}

=item doclen

Get the document length for this result.

=cut

sub doclen {
    my $self = shift;
    if (@_) { $self->{url} = shift; }
    return $self->{doclen};
}


=item tf

Get the term frequency value for this result.

=cut

sub tf {
    my $self = shift;
    if (@_) { $self->{url} = shift; }
    return $self->{tf};
}

=item equals

Test equality between this resultItem and the given one (used mostly for
testing).

=cut

sub equals {
    my $self = shift;
    my $other = shift;
    return 0 unless ($other->isa('Search::Lemur::ResultItem'));
    return ($self->tf() == $other->tf()) &&
           ($self->doclen() == $other->doclen()) &&
           ($self->docid() == $other->docid());
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
