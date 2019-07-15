use utf8;

package SemanticWeb::Schema::TouristAttraction;

# ABSTRACT: A tourist attraction

use Moo;

extends qw/ SemanticWeb::Schema::Place /;


use MooX::JSON_LD 'TouristAttraction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has available_language => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'availableLanguage',
);



has tourist_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'touristType',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TouristAttraction - A tourist attraction

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html A tourist attraction. In principle any Thing can be a <a class="localLink"
href="http://schema.org/TouristAttraction">TouristAttraction</a>, from a <a
class="localLink" href="http://schema.org/Mountain">Mountain</a> and <a
class="localLink"
href="http://schema.org/LandmarksOrHistoricalBuildings">LandmarksOrHistoric
alBuildings</a> to a <a class="localLink"
href="http://schema.org/LocalBusiness">LocalBusiness</a>. This Type can be
used on its own to describe a general <a class="localLink"
href="http://schema.org/TouristAttraction">TouristAttraction</a>, or be
used as an <a class="localLink"
href="http://schema.org/additionalType">additionalType</a> to add tourist
attraction properties to any other type. (See examples below)

=head1 ATTRIBUTES

=head2 C<available_language>

C<availableLanguage>

=for html A language someone may use with or at the item, service or place. Please
use one of the language codes from the <a
href="http://tools.ietf.org/html/bcp47">IETF BCP 47 standard</a>. See also
<a class="localLink" href="http://schema.org/inLanguage">inLanguage</a>

A available_language should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Language']>

=item C<Str>

=back

=head2 C<tourist_type>

C<touristType>

Attraction suitable for type(s) of tourist. eg. Children, visitors from a
particular country, etc.

A tourist_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Audience']>

=item C<Str>

=back

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
