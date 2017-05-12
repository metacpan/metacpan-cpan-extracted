package SWISH::Prog::Lucy::Result;
use strict;
use warnings;

our $VERSION = '0.25';

use base qw( SWISH::Prog::Result );
use SWISH::3 ':constants';
use Carp;

__PACKAGE__->mk_accessors(qw( id relevant_fields property_map ));

=head1 NAME

SWISH::Prog::Lucy::Result - search result for Swish3 Apache Lucy backend

=head1 SYNOPSIS

 # see SWISH::Prog::Result

=head1 DESCRIPTION

SWISH::Prog::Lucy::Result is an Apache Lucy based Result
class for Swish3.

=head1 METHODS

Only new and overridden methods are documented here. See
the L<SWISH::Prog::Result> documentation.

=head2 relevant_fields

Returns an ARRAY ref of the field names in the result 
that matched the query. Will only be populated if
the Results object had find_relevant_fields() set to true.

=cut

=head2 uri

Returns the uri (unique term) for the result document.

=cut

sub uri { $_[0]->{doc}->{swishdocpath} }

=head2 title

Returns the title of the result document.

=cut

sub title { $_[0]->{doc}->{swishtitle} }

=head2 mtime

Returns the last modified time of the result document.

=cut

sub mtime { $_[0]->{doc}->{swishlastmodified} }

=head2 summary

Returns the swishdescription of the result document.

=cut

sub summary { $_[0]->{doc}->{swishdescription} }

=head2 get_property( I<PropertyName> )

Returns the value for I<PropertyName>.

=cut

sub get_property {
    my $self = shift;
    my $propname = shift or croak "PropertyName required";

    # if $propname is an alias, use the real property name (how it is stored)
    if ( exists $self->{property_map}->{$propname} ) {
        $propname = $self->{property_map}->{$propname};
    }

    if ( !exists $self->{doc}->{$propname} ) {
        croak "no such PropertyName: $propname";
    }
    return $self->{doc}->{$propname};
}

=head2 property_map

Get the read-only hashref of PropertyNameAlias to PropertyName
values.

=head2 id

Get the read-only unique id from parent Searcher.

=cut

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog-lucy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog-Lucy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog::Lucy


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog-Lucy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog-Lucy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog-Lucy>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog-Lucy/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

