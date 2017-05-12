package Search::Query::Field::SWISH;
use Moo;
extends 'Search::Query::Field';

use namespace::autoclean;

has 'type'   => ( is => 'rw' );
has 'is_int' => ( is => 'rw' );

our $VERSION = '0.307';

=head1 NAME

Search::Query::Field::SWISH - query field representing a Swish MetaName

=head1 SYNOPSIS

 my $field = Search::Query::Field::SWISH->new( 
    name        => 'foo',
    alias_for   => [qw( bar bing )], 
 );

=head1 DESCRIPTION

Search::Query::Field::SWISH implements field
validation and aliasing in SWISH search queries.

=head1 METHODS

This class is a subclass of Search::Query::Field. Only new or overridden
methods are documented here.

=head2 BUILD

Available params are also standard attribute accessor methods.

=over

=item type

The column type.a

=item is_int

Set if C<type> matches m/int|num|date/.

=back

=cut

sub BUILD {
    my $self = shift;

    $self->{type} ||= 'char';

    # numeric types
    if ( $self->{type} =~ m/int|date|num/ ) {
        $self->{is_int} = 1;
    }

    # text types
    else {
        $self->{is_int} = 0;
    }

}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-query at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Query>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Query


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Query>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Query>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Query>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Query/>

=back


=head1 ACKNOWLEDGEMENTS

This module started as a fork of Search::QueryParser by
Laurent Dami.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
