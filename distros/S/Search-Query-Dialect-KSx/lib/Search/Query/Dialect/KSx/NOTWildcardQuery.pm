package Search::Query::Dialect::KSx::NOTWildcardQuery;
use strict;
use warnings;
use base qw( Search::Query::Dialect::KSx::WildcardQuery );
use Carp;

our $VERSION = '0.201';

=head1 NAME

Search::Query::Dialect::KSx::NOTWildcardQuery - KinoSearch query extension

=head1 SYNOPSIS

 my $query = Search::Query->parser( dialect => 'KSx' )->parse('myfield!:foo*');
 my $ks_query = $query->as_ks_query();
 # $ks_query isa NOTWildcardQuery

=head1 DESCRIPTION

If a WildcardQuery is equivalent to this:

 $term =~ m/$query/

then a NOTWildcardQuery is equivalent to this:

 $term !~ m/$query/

B<Note> that the as_ks_query() method in Dialect::KSx does B<not> use
this class but instead wraps a WildcardQuery in a NOTQuery, which allows
for matching null values as well. So currently this class is not used
by Search::Query::Dialect::KSx but is included here in case someone finds it 
useful.

=head1 METHODS

This class isa Search::Query::Dialect::KSx::WildcardQuery subclass.
Only new or overridden methods are documented.

=head2 make_compiler

Returns a Search::Query::Dialect::KSx::Compiler object.

=cut

sub make_compiler {
    my $self = shift;
    return Search::Query::Dialect::KSx::Compiler->new(
        @_,
        parent  => $self,
        include => 0,
    );
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-query-dialect-ksx at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Query-Dialect-KSx>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Query::Dialect::KSx


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Query-Dialect-KSx>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Query-Dialect-KSx>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Query-Dialect-KSx>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Query-Dialect-KSx/>

=back

=head1 ACKNOWLEDGEMENTS

Based on the sample PrefixQuery code in the KinoSearch distribution.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
