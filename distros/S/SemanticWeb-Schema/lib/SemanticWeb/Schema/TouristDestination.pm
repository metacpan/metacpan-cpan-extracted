use utf8;

package SemanticWeb::Schema::TouristDestination;

# ABSTRACT: A tourist destination

use Moo;

extends qw/ SemanticWeb::Schema::Place /;


use MooX::JSON_LD 'TouristDestination';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.2';


has includes_attraction => (
    is        => 'rw',
    predicate => '_has_includes_attraction',
    json_ld   => 'includesAttraction',
);



has tourist_type => (
    is        => 'rw',
    predicate => '_has_tourist_type',
    json_ld   => 'touristType',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TouristDestination - A tourist destination

=head1 VERSION

version v7.0.2

=head1 DESCRIPTION

=for html <p>A tourist destination. In principle any <a class="localLink"
href="http://schema.org/Place">Place</a> can be a <a class="localLink"
href="http://schema.org/TouristDestination">TouristDestination</a> from a
<a class="localLink" href="http://schema.org/City">City</a>, <a
class="localLink" href="http://schema.org/Region">Region</a> or <a
class="localLink" href="http://schema.org/Country">Country</a> to an <a
class="localLink" href="http://schema.org/AmusementPark">AmusementPark</a>
or <a class="localLink" href="http://schema.org/Hotel">Hotel</a>. This Type
can be used on its own to describe a general <a class="localLink"
href="http://schema.org/TouristDestination">TouristDestination</a>, or be
used as an <a class="localLink"
href="http://schema.org/additionalType">additionalType</a> to add tourist
relevant properties to any other <a class="localLink"
href="http://schema.org/Place">Place</a>. A <a class="localLink"
href="http://schema.org/TouristDestination">TouristDestination</a> is
defined as a <a class="localLink" href="http://schema.org/Place">Place</a>
that contains, or is colocated with, one or more <a class="localLink"
href="http://schema.org/TouristAttraction">TouristAttraction</a>s, often
linked by a similar theme or interest to a particular <a class="localLink"
href="http://schema.org/touristType">touristType</a>. The <a
href="http://www2.unwto.org/">UNWTO</a> defines Destination (main
destination of a tourism trip) as the place visited that is central to the
decision to take the trip. (See examples below).<p>

=head1 ATTRIBUTES

=head2 C<includes_attraction>

C<includesAttraction>

Attraction located at destination.

A includes_attraction should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::TouristAttraction']>

=back

=head2 C<_has_includes_attraction>

A predicate for the L</includes_attraction> attribute.

=head2 C<tourist_type>

C<touristType>

Attraction suitable for type(s) of tourist. eg. Children, visitors from a
particular country, etc.

A tourist_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Audience']>

=item C<Str>

=back

=head2 C<_has_tourist_type>

A predicate for the L</tourist_type> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Place>

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
