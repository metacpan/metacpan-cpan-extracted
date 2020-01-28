use utf8;

package SemanticWeb::Schema::TouristTrip;

# ABSTRACT: A tourist trip

use Moo;

extends qw/ SemanticWeb::Schema::Trip /;


use MooX::JSON_LD 'TouristTrip';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.0';


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

SemanticWeb::Schema::TouristTrip - A tourist trip

=head1 VERSION

version v6.0.0

=head1 DESCRIPTION

=for html <p>A tourist trip. A created itinerary of visits to one or more places of
interest (<a class="localLink"
href="http://schema.org/TouristAttraction">TouristAttraction</a>/<a
class="localLink"
href="http://schema.org/TouristDestination">TouristDestination</a>) often
linked by a similar theme, geographic area, or interest to a particular <a
class="localLink" href="http://schema.org/touristType">touristType</a>. The
<a href="http://www2.unwto.org/">UNWTO</a> defines tourism trip as the Trip
taken by visitors. (See examples below).<p>

=head1 ATTRIBUTES

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

L<SemanticWeb::Schema::Trip>

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
