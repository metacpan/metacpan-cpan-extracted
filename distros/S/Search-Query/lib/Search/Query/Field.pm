package Search::Query::Field;
use Moo;
use Carp;

use namespace::autoclean;

our $VERSION = '0.307';

has 'name'      => ( is => 'rw' );
has 'alias_for' => ( is => 'rw' );
has 'callback'  => ( is => 'rw' );
has 'error'     => ( is => 'rw' );

=head1 NAME

Search::Query::Field - base class for query fields

=head1 SYNOPSIS

 my $field = Search::Query::Field->new( 
    name        => 'foo',
    alias_for   => [qw( bar bing )], 
 );

=head1 DESCRIPTION

Search::Query::Field is a base class for implementing field
validation and aliasing in search queries.

=head1 METHODS

=head2 name

Get/set the name of the field.

=head2 alias_for

Get/set the alternate names for the field. Can be a string or array ref.

=head2 callback

Standard attribute accessor. Expects a CODE reference.

If defined on a Field object, the callback is invoked whenever a Clause
is stringified or serialized. The CODE reference should expect 3 arguments:
the field name, the operator and the value. It should return a serialized
or serializable value. Example:

 $field->callback(sub {
     my ($field, $op, $value) = @_;
     return "$field $op $value";
 });

=head2 validate( I<field_value> )

The base method always returns true.

=cut

sub validate {1}

=head2 error

Get/set the error string for the Field object. The return value
of this method is included by the Parser in any error message
whenever validate() returns false.

=cut

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
