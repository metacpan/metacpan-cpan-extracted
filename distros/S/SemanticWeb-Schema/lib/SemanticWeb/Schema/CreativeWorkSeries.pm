use utf8;

package SemanticWeb::Schema::CreativeWorkSeries;

# ABSTRACT: A CreativeWorkSeries in schema

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork SemanticWeb::Schema::Series /;


use MooX::JSON_LD 'CreativeWorkSeries';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has end_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'endDate',
);



has issn => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'issn',
);



has start_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'startDate',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CreativeWorkSeries - A CreativeWorkSeries in schema

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html A CreativeWorkSeries in schema.org is a group of related items, typically
but not necessarily of the same kind. CreativeWorkSeries are usually
organized into some order, often chronological. Unlike <a class="localLink"
href="http://schema.org/ItemList">ItemList</a> which is a general purpose
data structure for lists of things, the emphasis with CreativeWorkSeries is
on published materials (written e.g. books and periodicals, or media such
as tv, radio and games).<br/><br/> Specific subtypes are available for
describing <a class="localLink"
href="http://schema.org/TVSeries">TVSeries</a>, <a class="localLink"
href="http://schema.org/RadioSeries">RadioSeries</a>, <a class="localLink"
href="http://schema.org/MovieSeries">MovieSeries</a>, <a class="localLink"
href="http://schema.org/BookSeries">BookSeries</a>, <a class="localLink"
href="http://schema.org/Periodical">Periodical</a> and <a class="localLink"
href="http://schema.org/VideoGameSeries">VideoGameSeries</a>. In each case,
the <a class="localLink" href="http://schema.org/hasPart">hasPart</a> / <a
class="localLink" href="http://schema.org/isPartOf">isPartOf</a> properties
can be used to relate the CreativeWorkSeries to its parts. The general
CreativeWorkSeries type serves largely just to organize these more specific
and practical subtypes.<br/><br/> It is common for properties applicable to
an item from the series to be usefully applied to the containing group.
Schema.org attempts to anticipate some of these cases, but publishers
should be free to apply properties of the series parts to the series as a
whole wherever they seem appropriate.

=head1 ATTRIBUTES

=head2 C<end_date>

C<endDate>

=for html The end date and time of the item (in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>).

A end_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<issn>

The International Standard Serial Number (ISSN) that identifies this serial
publication. You can repeat this property to identify different formats of,
or the linking ISSN (ISSN-L) for, this serial publication.

A issn should be one of the following types:

=over

=item C<Str>

=back

=head2 C<start_date>

C<startDate>

=for html The start date and time of the item (in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>).

A start_date should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Series>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
