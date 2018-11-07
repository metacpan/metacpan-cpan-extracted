use utf8;

package SemanticWeb::Schema::LodgingBusiness;

# ABSTRACT: A lodging business

use Moo;

extends qw/ SemanticWeb::Schema::LocalBusiness /;


use MooX::JSON_LD 'LodgingBusiness';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has amenity_feature => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'amenityFeature',
);



has audience => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'audience',
);



has available_language => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'availableLanguage',
);



has checkin_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'checkinTime',
);



has checkout_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'checkoutTime',
);



has pets_allowed => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'petsAllowed',
);



has star_rating => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'starRating',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::LodgingBusiness - A lodging business

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

A lodging business, such as a motel, hotel, or inn.

=head1 ATTRIBUTES

=head2 C<amenity_feature>

C<amenityFeature>

An amenity feature (e.g. a characteristic or service) of the Accommodation.
This generic property does not make a statement about whether the feature
is included in an offer for the main accommodation or available at extra
costs.

A amenity_feature should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::LocationFeatureSpecification']>

=back

=head2 C<audience>

An intended audience, i.e. a group for whom something was created.

A audience should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Audience']>

=back

=head2 C<available_language>

C<availableLanguage>

=for html A language someone may use with or at the item, service or place. Please
use one of the language codes from the <a
href="http://tools.ietf.org/html/bcp47">IETF BCP 47 standard</a>. See also
<a class="localLink" href="http://schema.org/inLanguage">inLanguage</a>

A available_language should be one of the following types:

=over

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::Language']>

=back

=head2 C<checkin_time>

C<checkinTime>

The earliest someone may check into a lodging establishment.

A checkin_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<checkout_time>

C<checkoutTime>

The latest someone may check out of a lodging establishment.

A checkout_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<pets_allowed>

C<petsAllowed>

Indicates whether pets are allowed to enter the accommodation or lodging
business. More detailed information can be put in a text value.

A pets_allowed should be one of the following types:

=over

=item C<Str>

=item C<Bool>

=back

=head2 C<star_rating>

C<starRating>

An official rating for a lodging business or food establishment, e.g. from
national associations or standards bodies. Use the author property to
indicate the rating organization, e.g. as an Organization with name such as
(e.g. HOTREC, DEHOGA, WHR, or Hotelstars).

A star_rating should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Rating']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::LocalBusiness>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
