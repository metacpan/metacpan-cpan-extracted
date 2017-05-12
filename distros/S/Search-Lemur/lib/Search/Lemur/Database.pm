use warnings;
use strict;

package Search::Lemur::Database;



=head1 NAME

Lemur::Database

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.00';


=head1 DESCRIPTION

Represent information about an available database.


=cut

=head2 Main Methods

=over 2

=cut

# create a new C<Database> object.  This should only be called by a
# Lemur object, in its _makedbs method.  One of these will be created 
# for every database available to the Lemur server.  
# 
# The arguments are database number, title, stop status, stem status,
# number of docs, number of terms, number of unique terms, average 
# document length.  The stop status and stem status
# are one of 1 or 0, for true and false, respectively.
#
# If these arguments are not given, this will return undef
sub _new {
    my $class = shift;
    my $self = {};
    if (scalar(@_) >= 8) {
        my ($num, $title, $stop, $stem, $numdocs, $numterms, $numuniq, $avgdoclen) = @_;
        $self = { num => $num,
                 title => $title,
                 stop => $stop,
                 stem => $stem,
                 numdocs => $numdocs,
                 numterms => $numterms,
                 numuniq => $numuniq,
                 avgdoclen => $avgdoclen };
    } else { return undef; }
    bless $self, $class;
    return $self;
}

=item num()

Get the database number.  This number is useful to pass to 
Lemur->d() to specify which database you want to use.

=cut

sub num {
    my $self = shift;
    return $self->{num};
}


=item title()

Get the title of this database.  

=cut

sub title {
    my $self = shift;
    return $self->{title};
}

=item stem()

Gets the stemming status of this database.  Returns 1 if the 
database is stemmed, 0 if not.

=cut

sub stem {
    my $self = shift;
    return $self->{stem};
}


=item stop()

Returns the stop word status of this database.  Returns 1 if
the database is stop-worded, 0 if not.

=cut

sub stop {
    my $self = shift;
    return $self->{stop};
}



=item numdocs()

Returns the number of documents in this database.

=cut

sub numdocs {
    my $self = shift;
    return $self->{numdocs};
}




=item numterms()

Returns the number of terms in this database.

=cut

sub numterms {
    my $self = shift;
    return $self->{numterms};
}



=item numuniq()

Returns the number of unique terms in this database.

=cut

sub numuniq {
    my $self = shift;
    return $self->{numuniq};
}




=item avgdoclen()

Returns the average document length in this database.

=cut

sub avgdoclen {
    my $self = shift;
    return $self->{avgdoclen};
}



=item equals

Test equality between this database and the given one (used mostly for
testing).

=cut

sub equals {
    my $self = shift;
    my $other = shift;
    return 0 unless ($other->isa('Search::Lemur::Database'));
    return ($self->{title} eq $other->{title}) && 
           ($self->{num} == $other->{num}) &&
           ($self->{stem} == $other->{stem}) && 
           ($self->{stop} == $other->{stop}) &&
           ($self->{numdocs} == $other->{numdocs}) &&
           ($self->{numuniq} == $other->{numuniq}) &&
           ($self->{avgdoclen} == $other->{avgdoclen}) &&
           ($self->{numterms} == $other->{numterms});
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
