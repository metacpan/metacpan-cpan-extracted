use utf8;

package SemanticWeb::Schema::Person;

# ABSTRACT: A person (alive

use Moo;

extends qw/ SemanticWeb::Schema::Thing /;


use MooX::JSON_LD 'Person';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has additional_name => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'additionalName',
);



has address => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'address',
);



has affiliation => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'affiliation',
);



has alumni_of => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'alumniOf',
);



has award => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'award',
);



has awards => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'awards',
);



has birth_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'birthDate',
);



has birth_place => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'birthPlace',
);



has brand => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'brand',
);



has children => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'children',
);



has colleague => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'colleague',
);



has colleagues => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'colleagues',
);



has contact_point => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'contactPoint',
);



has contact_points => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'contactPoints',
);



has death_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'deathDate',
);



has death_place => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'deathPlace',
);



has duns => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'duns',
);



has email => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'email',
);



has family_name => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'familyName',
);



has fax_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'faxNumber',
);



has follows => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'follows',
);



has funder => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'funder',
);



has gender => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'gender',
);



has given_name => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'givenName',
);



has global_location_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'globalLocationNumber',
);



has has_occupation => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hasOccupation',
);



has has_offer_catalog => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hasOfferCatalog',
);



has has_pos => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hasPOS',
);



has height => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'height',
);



has home_location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'homeLocation',
);



has honorific_prefix => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'honorificPrefix',
);



has honorific_suffix => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'honorificSuffix',
);



has isic_v4 => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'isicV4',
);



has knows => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'knows',
);



has makes_offer => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'makesOffer',
);



has member_of => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'memberOf',
);



has naics => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'naics',
);



has nationality => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'nationality',
);



has net_worth => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'netWorth',
);



has owns => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'owns',
);



has parent => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'parent',
);



has parents => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'parents',
);



has performer_in => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'performerIn',
);



has publishing_principles => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'publishingPrinciples',
);



has related_to => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'relatedTo',
);



has seeks => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'seeks',
);



has sibling => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'sibling',
);



has siblings => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'siblings',
);



has sponsor => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'sponsor',
);



has spouse => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'spouse',
);



has tax_id => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'taxID',
);



has telephone => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'telephone',
);



has vat_id => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'vatID',
);



has weight => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'weight',
);



has work_location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'workLocation',
);



has works_for => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'worksFor',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Person - A person (alive

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A person (alive, dead, undead, or fictional).

=head1 ATTRIBUTES

=head2 C<additional_name>

C<additionalName>

An additional name for a Person, can be used for a middle name.

A additional_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<address>

Physical address of the item.

A address should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PostalAddress']>

=item C<Str>

=back

=head2 C<affiliation>

An organization that this person is affiliated with. For example, a
school/university, a club, or a team.

A affiliation should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<alumni_of>

C<alumniOf>

An organization that the person is an alumni of.

A alumni_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::EducationalOrganization']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<award>

An award won by or for this item.

A award should be one of the following types:

=over

=item C<Str>

=back

=head2 C<awards>

Awards won by or for this item.

A awards should be one of the following types:

=over

=item C<Str>

=back

=head2 C<birth_date>

C<birthDate>

Date of birth.

A birth_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<birth_place>

C<birthPlace>

The place where the person was born.

A birth_place should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<brand>

The brand(s) associated with a product or service, or the brand(s)
maintained by an organization or business person.

A brand should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Brand']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<children>

A child of the person.

A children should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<colleague>

A colleague of the person.

A colleague should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=item C<Str>

=back

=head2 C<colleagues>

A colleague of the person.

A colleagues should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<contact_point>

C<contactPoint>

A contact point for a person or organization.

A contact_point should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=back

=head2 C<contact_points>

C<contactPoints>

A contact point for a person or organization.

A contact_points should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=back

=head2 C<death_date>

C<deathDate>

Date of death.

A death_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<death_place>

C<deathPlace>

The place where the person died.

A death_place should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<duns>

The Dun &amp; Bradstreet DUNS number for identifying an organization or
business person.

A duns should be one of the following types:

=over

=item C<Str>

=back

=head2 C<email>

Email address.

A email should be one of the following types:

=over

=item C<Str>

=back

=head2 C<family_name>

C<familyName>

Family name. In the U.S., the last name of an Person. This can be used
along with givenName instead of the name property.

A family_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<fax_number>

C<faxNumber>

The fax number.

A fax_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<follows>

The most generic uni-directional social relation.

A follows should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<funder>

A person or organization that supports (sponsors) something through some
kind of financial contribution.

A funder should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<gender>

Gender of the person. While http://schema.org/Male and
http://schema.org/Female may be used, text strings are also acceptable for
people who do not identify as a binary gender.

A gender should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GenderType']>

=item C<Str>

=back

=head2 C<given_name>

C<givenName>

Given name. In the U.S., the first name of a Person. This can be used along
with familyName instead of the name property.

A given_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<global_location_number>

C<globalLocationNumber>

=for html The <a href="http://www.gs1.org/gln">Global Location Number</a> (GLN,
sometimes also referred to as International Location Number or ILN) of the
respective organization, person, or place. The GLN is a 13-digit number
used to identify parties and physical locations.

A global_location_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<has_occupation>

C<hasOccupation>

The Person's occupation. For past professions, use Role for expressing
dates.

A has_occupation should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Occupation']>

=back

=head2 C<has_offer_catalog>

C<hasOfferCatalog>

Indicates an OfferCatalog listing for this Organization, Person, or
Service.

A has_offer_catalog should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::OfferCatalog']>

=back

=head2 C<has_pos>

C<hasPOS>

Points-of-Sales operated by the organization or person.

A has_pos should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<height>

The height of the item.

A height should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Distance']>

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<home_location>

C<homeLocation>

A contact location for a person's residence.

A home_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<honorific_prefix>

C<honorificPrefix>

An honorific prefix preceding a Person's name such as Dr/Mrs/Mr.

A honorific_prefix should be one of the following types:

=over

=item C<Str>

=back

=head2 C<honorific_suffix>

C<honorificSuffix>

An honorific suffix preceding a Person's name such as M.D. /PhD/MSCSW.

A honorific_suffix should be one of the following types:

=over

=item C<Str>

=back

=head2 C<isic_v4>

C<isicV4>

The International Standard of Industrial Classification of All Economic
Activities (ISIC), Revision 4 code for a particular organization, business
person, or place.

A isic_v4 should be one of the following types:

=over

=item C<Str>

=back

=head2 C<knows>

The most generic bi-directional social/work relation.

A knows should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<makes_offer>

C<makesOffer>

A pointer to products or services offered by the organization or person.

A makes_offer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<member_of>

C<memberOf>

An Organization (or ProgramMembership) to which this Person or Organization
belongs.

A member_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::ProgramMembership']>

=back

=head2 C<naics>

The North American Industry Classification System (NAICS) code for a
particular organization or business person.

A naics should be one of the following types:

=over

=item C<Str>

=back

=head2 C<nationality>

Nationality of the person.

A nationality should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Country']>

=back

=head2 C<net_worth>

C<netWorth>

The total financial value of the person as calculated by subtracting assets
from liabilities.

A net_worth should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=item C<InstanceOf['SemanticWeb::Schema::PriceSpecification']>

=back

=head2 C<owns>

Products owned by the organization or person.

A owns should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::OwnershipInfo']>

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=back

=head2 C<parent>

A parent of this person.

A parent should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<parents>

A parents of the person.

A parents should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<performer_in>

C<performerIn>

Event that this person is a performer or participant in.

A performer_in should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Event']>

=back

=head2 C<publishing_principles>

C<publishingPrinciples>

=for html The publishingPrinciples property indicates (typically via <a
class="localLink" href="http://schema.org/URL">URL</a>) a document
describing the editorial principles of an <a class="localLink"
href="http://schema.org/Organization">Organization</a> (or individual e.g.
a <a class="localLink" href="http://schema.org/Person">Person</a> writing a
blog) that relate to their activities as a publisher, e.g. ethics or
diversity policies. When applied to a <a class="localLink"
href="http://schema.org/CreativeWork">CreativeWork</a> (e.g. <a
class="localLink" href="http://schema.org/NewsArticle">NewsArticle</a>) the
principles are those of the party primarily responsible for the creation of
the <a class="localLink"
href="http://schema.org/CreativeWork">CreativeWork</a>.<br/><br/> While
such policies are most typically expressed in natural language, sometimes
related information (e.g. indicating a <a class="localLink"
href="http://schema.org/funder">funder</a>) can be expressed using
schema.org terminology.

A publishing_principles should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<related_to>

C<relatedTo>

The most generic familial relation.

A related_to should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<seeks>

A pointer to products or services sought by the organization or person
(demand).

A seeks should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Demand']>

=back

=head2 C<sibling>

A sibling of the person.

A sibling should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<siblings>

A sibling of the person.

A siblings should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<sponsor>

A person or organization that supports a thing through a pledge, promise,
or financial contribution. e.g. a sponsor of a Medical Study or a corporate
sponsor of an event.

A sponsor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<spouse>

The person's spouse.

A spouse should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<tax_id>

C<taxID>

The Tax / Fiscal ID of the organization or person, e.g. the TIN in the US
or the CIF/NIF in Spain.

A tax_id should be one of the following types:

=over

=item C<Str>

=back

=head2 C<telephone>

The telephone number.

A telephone should be one of the following types:

=over

=item C<Str>

=back

=head2 C<vat_id>

C<vatID>

The Value-added Tax ID of the organization or person.

A vat_id should be one of the following types:

=over

=item C<Str>

=back

=head2 C<weight>

The weight of the product or person.

A weight should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<work_location>

C<workLocation>

A contact location for a person's place of work.

A work_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<works_for>

C<worksFor>

Organizations that the person works for.

A works_for should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Thing>

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
