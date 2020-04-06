use utf8;

package SemanticWeb::Schema::Person;

# ABSTRACT: A person (alive

use Moo;

extends qw/ SemanticWeb::Schema::Thing /;


use MooX::JSON_LD 'Person';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has additional_name => (
    is        => 'rw',
    predicate => '_has_additional_name',
    json_ld   => 'additionalName',
);



has address => (
    is        => 'rw',
    predicate => '_has_address',
    json_ld   => 'address',
);



has affiliation => (
    is        => 'rw',
    predicate => '_has_affiliation',
    json_ld   => 'affiliation',
);



has alumni_of => (
    is        => 'rw',
    predicate => '_has_alumni_of',
    json_ld   => 'alumniOf',
);



has award => (
    is        => 'rw',
    predicate => '_has_award',
    json_ld   => 'award',
);



has awards => (
    is        => 'rw',
    predicate => '_has_awards',
    json_ld   => 'awards',
);



has birth_date => (
    is        => 'rw',
    predicate => '_has_birth_date',
    json_ld   => 'birthDate',
);



has birth_place => (
    is        => 'rw',
    predicate => '_has_birth_place',
    json_ld   => 'birthPlace',
);



has brand => (
    is        => 'rw',
    predicate => '_has_brand',
    json_ld   => 'brand',
);



has call_sign => (
    is        => 'rw',
    predicate => '_has_call_sign',
    json_ld   => 'callSign',
);



has children => (
    is        => 'rw',
    predicate => '_has_children',
    json_ld   => 'children',
);



has colleague => (
    is        => 'rw',
    predicate => '_has_colleague',
    json_ld   => 'colleague',
);



has colleagues => (
    is        => 'rw',
    predicate => '_has_colleagues',
    json_ld   => 'colleagues',
);



has contact_point => (
    is        => 'rw',
    predicate => '_has_contact_point',
    json_ld   => 'contactPoint',
);



has contact_points => (
    is        => 'rw',
    predicate => '_has_contact_points',
    json_ld   => 'contactPoints',
);



has death_date => (
    is        => 'rw',
    predicate => '_has_death_date',
    json_ld   => 'deathDate',
);



has death_place => (
    is        => 'rw',
    predicate => '_has_death_place',
    json_ld   => 'deathPlace',
);



has duns => (
    is        => 'rw',
    predicate => '_has_duns',
    json_ld   => 'duns',
);



has email => (
    is        => 'rw',
    predicate => '_has_email',
    json_ld   => 'email',
);



has family_name => (
    is        => 'rw',
    predicate => '_has_family_name',
    json_ld   => 'familyName',
);



has fax_number => (
    is        => 'rw',
    predicate => '_has_fax_number',
    json_ld   => 'faxNumber',
);



has follows => (
    is        => 'rw',
    predicate => '_has_follows',
    json_ld   => 'follows',
);



has funder => (
    is        => 'rw',
    predicate => '_has_funder',
    json_ld   => 'funder',
);



has gender => (
    is        => 'rw',
    predicate => '_has_gender',
    json_ld   => 'gender',
);



has given_name => (
    is        => 'rw',
    predicate => '_has_given_name',
    json_ld   => 'givenName',
);



has global_location_number => (
    is        => 'rw',
    predicate => '_has_global_location_number',
    json_ld   => 'globalLocationNumber',
);



has has_credential => (
    is        => 'rw',
    predicate => '_has_has_credential',
    json_ld   => 'hasCredential',
);



has has_occupation => (
    is        => 'rw',
    predicate => '_has_has_occupation',
    json_ld   => 'hasOccupation',
);



has has_offer_catalog => (
    is        => 'rw',
    predicate => '_has_has_offer_catalog',
    json_ld   => 'hasOfferCatalog',
);



has has_pos => (
    is        => 'rw',
    predicate => '_has_has_pos',
    json_ld   => 'hasPOS',
);



has height => (
    is        => 'rw',
    predicate => '_has_height',
    json_ld   => 'height',
);



has home_location => (
    is        => 'rw',
    predicate => '_has_home_location',
    json_ld   => 'homeLocation',
);



has honorific_prefix => (
    is        => 'rw',
    predicate => '_has_honorific_prefix',
    json_ld   => 'honorificPrefix',
);



has honorific_suffix => (
    is        => 'rw',
    predicate => '_has_honorific_suffix',
    json_ld   => 'honorificSuffix',
);



has interaction_statistic => (
    is        => 'rw',
    predicate => '_has_interaction_statistic',
    json_ld   => 'interactionStatistic',
);



has isic_v4 => (
    is        => 'rw',
    predicate => '_has_isic_v4',
    json_ld   => 'isicV4',
);



has job_title => (
    is        => 'rw',
    predicate => '_has_job_title',
    json_ld   => 'jobTitle',
);



has knows => (
    is        => 'rw',
    predicate => '_has_knows',
    json_ld   => 'knows',
);



has knows_about => (
    is        => 'rw',
    predicate => '_has_knows_about',
    json_ld   => 'knowsAbout',
);



has knows_language => (
    is        => 'rw',
    predicate => '_has_knows_language',
    json_ld   => 'knowsLanguage',
);



has makes_offer => (
    is        => 'rw',
    predicate => '_has_makes_offer',
    json_ld   => 'makesOffer',
);



has member_of => (
    is        => 'rw',
    predicate => '_has_member_of',
    json_ld   => 'memberOf',
);



has naics => (
    is        => 'rw',
    predicate => '_has_naics',
    json_ld   => 'naics',
);



has nationality => (
    is        => 'rw',
    predicate => '_has_nationality',
    json_ld   => 'nationality',
);



has net_worth => (
    is        => 'rw',
    predicate => '_has_net_worth',
    json_ld   => 'netWorth',
);



has owns => (
    is        => 'rw',
    predicate => '_has_owns',
    json_ld   => 'owns',
);



has parent => (
    is        => 'rw',
    predicate => '_has_parent',
    json_ld   => 'parent',
);



has parents => (
    is        => 'rw',
    predicate => '_has_parents',
    json_ld   => 'parents',
);



has performer_in => (
    is        => 'rw',
    predicate => '_has_performer_in',
    json_ld   => 'performerIn',
);



has publishing_principles => (
    is        => 'rw',
    predicate => '_has_publishing_principles',
    json_ld   => 'publishingPrinciples',
);



has related_to => (
    is        => 'rw',
    predicate => '_has_related_to',
    json_ld   => 'relatedTo',
);



has seeks => (
    is        => 'rw',
    predicate => '_has_seeks',
    json_ld   => 'seeks',
);



has sibling => (
    is        => 'rw',
    predicate => '_has_sibling',
    json_ld   => 'sibling',
);



has siblings => (
    is        => 'rw',
    predicate => '_has_siblings',
    json_ld   => 'siblings',
);



has sponsor => (
    is        => 'rw',
    predicate => '_has_sponsor',
    json_ld   => 'sponsor',
);



has spouse => (
    is        => 'rw',
    predicate => '_has_spouse',
    json_ld   => 'spouse',
);



has tax_id => (
    is        => 'rw',
    predicate => '_has_tax_id',
    json_ld   => 'taxID',
);



has telephone => (
    is        => 'rw',
    predicate => '_has_telephone',
    json_ld   => 'telephone',
);



has vat_id => (
    is        => 'rw',
    predicate => '_has_vat_id',
    json_ld   => 'vatID',
);



has weight => (
    is        => 'rw',
    predicate => '_has_weight',
    json_ld   => 'weight',
);



has work_location => (
    is        => 'rw',
    predicate => '_has_work_location',
    json_ld   => 'workLocation',
);



has works_for => (
    is        => 'rw',
    predicate => '_has_works_for',
    json_ld   => 'worksFor',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Person - A person (alive

=head1 VERSION

version v7.0.3

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

=head2 C<_has_additional_name>

A predicate for the L</additional_name> attribute.

=head2 C<address>

Physical address of the item.

A address should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PostalAddress']>

=item C<Str>

=back

=head2 C<_has_address>

A predicate for the L</address> attribute.

=head2 C<affiliation>

An organization that this person is affiliated with. For example, a
school/university, a club, or a team.

A affiliation should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_affiliation>

A predicate for the L</affiliation> attribute.

=head2 C<alumni_of>

C<alumniOf>

An organization that the person is an alumni of.

A alumni_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::EducationalOrganization']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_alumni_of>

A predicate for the L</alumni_of> attribute.

=head2 C<award>

An award won by or for this item.

A award should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_award>

A predicate for the L</award> attribute.

=head2 C<awards>

Awards won by or for this item.

A awards should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_awards>

A predicate for the L</awards> attribute.

=head2 C<birth_date>

C<birthDate>

Date of birth.

A birth_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_birth_date>

A predicate for the L</birth_date> attribute.

=head2 C<birth_place>

C<birthPlace>

The place where the person was born.

A birth_place should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_birth_place>

A predicate for the L</birth_place> attribute.

=head2 C<brand>

The brand(s) associated with a product or service, or the brand(s)
maintained by an organization or business person.

A brand should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Brand']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_brand>

A predicate for the L</brand> attribute.

=head2 C<call_sign>

C<callSign>

=for html <p>A <a href="https://en.wikipedia.org/wiki/Call_sign">callsign</a>, as
used in broadcasting and radio communications to identify people, radio and
TV stations, or vehicles.<p>

A call_sign should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_call_sign>

A predicate for the L</call_sign> attribute.

=head2 C<children>

A child of the person.

A children should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_children>

A predicate for the L</children> attribute.

=head2 C<colleague>

A colleague of the person.

A colleague should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=item C<Str>

=back

=head2 C<_has_colleague>

A predicate for the L</colleague> attribute.

=head2 C<colleagues>

A colleague of the person.

A colleagues should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_colleagues>

A predicate for the L</colleagues> attribute.

=head2 C<contact_point>

C<contactPoint>

A contact point for a person or organization.

A contact_point should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=back

=head2 C<_has_contact_point>

A predicate for the L</contact_point> attribute.

=head2 C<contact_points>

C<contactPoints>

A contact point for a person or organization.

A contact_points should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=back

=head2 C<_has_contact_points>

A predicate for the L</contact_points> attribute.

=head2 C<death_date>

C<deathDate>

Date of death.

A death_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_death_date>

A predicate for the L</death_date> attribute.

=head2 C<death_place>

C<deathPlace>

The place where the person died.

A death_place should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_death_place>

A predicate for the L</death_place> attribute.

=head2 C<duns>

The Dun &amp; Bradstreet DUNS number for identifying an organization or
business person.

A duns should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_duns>

A predicate for the L</duns> attribute.

=head2 C<email>

Email address.

A email should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_email>

A predicate for the L</email> attribute.

=head2 C<family_name>

C<familyName>

Family name. In the U.S., the last name of an Person. This can be used
along with givenName instead of the name property.

A family_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_family_name>

A predicate for the L</family_name> attribute.

=head2 C<fax_number>

C<faxNumber>

The fax number.

A fax_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_fax_number>

A predicate for the L</fax_number> attribute.

=head2 C<follows>

The most generic uni-directional social relation.

A follows should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_follows>

A predicate for the L</follows> attribute.

=head2 C<funder>

A person or organization that supports (sponsors) something through some
kind of financial contribution.

A funder should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_funder>

A predicate for the L</funder> attribute.

=head2 C<gender>

=for html <p>Gender of something, typically a <a class="localLink"
href="http://schema.org/Person">Person</a>, but possibly also fictional
characters, animals, etc. While http://schema.org/Male and
http://schema.org/Female may be used, text strings are also acceptable for
people who do not identify as a binary gender. The <a class="localLink"
href="http://schema.org/gender">gender</a> property can also be used in an
extended sense to cover e.g. the gender of sports teams. As with the gender
of individuals, we do not try to enumerate all possibilities. A
mixed-gender <a class="localLink"
href="http://schema.org/SportsTeam">SportsTeam</a> can be indicated with a
text value of "Mixed".<p>

A gender should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GenderType']>

=item C<Str>

=back

=head2 C<_has_gender>

A predicate for the L</gender> attribute.

=head2 C<given_name>

C<givenName>

Given name. In the U.S., the first name of a Person. This can be used along
with familyName instead of the name property.

A given_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_given_name>

A predicate for the L</given_name> attribute.

=head2 C<global_location_number>

C<globalLocationNumber>

=for html <p>The <a href="http://www.gs1.org/gln">Global Location Number</a> (GLN,
sometimes also referred to as International Location Number or ILN) of the
respective organization, person, or place. The GLN is a 13-digit number
used to identify parties and physical locations.<p>

A global_location_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_global_location_number>

A predicate for the L</global_location_number> attribute.

=head2 C<has_credential>

C<hasCredential>

A credential awarded to the Person or Organization.

A has_credential should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::EducationalOccupationalCredential']>

=back

=head2 C<_has_has_credential>

A predicate for the L</has_credential> attribute.

=head2 C<has_occupation>

C<hasOccupation>

The Person's occupation. For past professions, use Role for expressing
dates.

A has_occupation should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Occupation']>

=back

=head2 C<_has_has_occupation>

A predicate for the L</has_occupation> attribute.

=head2 C<has_offer_catalog>

C<hasOfferCatalog>

Indicates an OfferCatalog listing for this Organization, Person, or
Service.

A has_offer_catalog should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::OfferCatalog']>

=back

=head2 C<_has_has_offer_catalog>

A predicate for the L</has_offer_catalog> attribute.

=head2 C<has_pos>

C<hasPOS>

Points-of-Sales operated by the organization or person.

A has_pos should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_has_pos>

A predicate for the L</has_pos> attribute.

=head2 C<height>

The height of the item.

A height should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Distance']>

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_height>

A predicate for the L</height> attribute.

=head2 C<home_location>

C<homeLocation>

A contact location for a person's residence.

A home_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_home_location>

A predicate for the L</home_location> attribute.

=head2 C<honorific_prefix>

C<honorificPrefix>

An honorific prefix preceding a Person's name such as Dr/Mrs/Mr.

A honorific_prefix should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_honorific_prefix>

A predicate for the L</honorific_prefix> attribute.

=head2 C<honorific_suffix>

C<honorificSuffix>

An honorific suffix preceding a Person's name such as M.D. /PhD/MSCSW.

A honorific_suffix should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_honorific_suffix>

A predicate for the L</honorific_suffix> attribute.

=head2 C<interaction_statistic>

C<interactionStatistic>

The number of interactions for the CreativeWork using the WebSite or
SoftwareApplication. The most specific child type of InteractionCounter
should be used.

A interaction_statistic should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::InteractionCounter']>

=back

=head2 C<_has_interaction_statistic>

A predicate for the L</interaction_statistic> attribute.

=head2 C<isic_v4>

C<isicV4>

The International Standard of Industrial Classification of All Economic
Activities (ISIC), Revision 4 code for a particular organization, business
person, or place.

A isic_v4 should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_isic_v4>

A predicate for the L</isic_v4> attribute.

=head2 C<job_title>

C<jobTitle>

The job title of the person (for example, Financial Manager).

A job_title should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DefinedTerm']>

=item C<Str>

=back

=head2 C<_has_job_title>

A predicate for the L</job_title> attribute.

=head2 C<knows>

The most generic bi-directional social/work relation.

A knows should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_knows>

A predicate for the L</knows> attribute.

=head2 C<knows_about>

C<knowsAbout>

=for html <p>Of a <a class="localLink" href="http://schema.org/Person">Person</a>,
and less typically of an <a class="localLink"
href="http://schema.org/Organization">Organization</a>, to indicate a topic
that is known about - suggesting possible expertise but not implying it. We
do not distinguish skill levels here, or relate this to educational
content, events, objectives or <a class="localLink"
href="http://schema.org/JobPosting">JobPosting</a> descriptions.<p>

A knows_about should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=item C<Str>

=back

=head2 C<_has_knows_about>

A predicate for the L</knows_about> attribute.

=head2 C<knows_language>

C<knowsLanguage>

=for html <p>Of a <a class="localLink" href="http://schema.org/Person">Person</a>,
and less typically of an <a class="localLink"
href="http://schema.org/Organization">Organization</a>, to indicate a known
language. We do not distinguish skill levels or
reading/writing/speaking/signing here. Use language codes from the <a
href="http://tools.ietf.org/html/bcp47">IETF BCP 47 standard</a>.<p>

A knows_language should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Language']>

=item C<Str>

=back

=head2 C<_has_knows_language>

A predicate for the L</knows_language> attribute.

=head2 C<makes_offer>

C<makesOffer>

A pointer to products or services offered by the organization or person.

A makes_offer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<_has_makes_offer>

A predicate for the L</makes_offer> attribute.

=head2 C<member_of>

C<memberOf>

An Organization (or ProgramMembership) to which this Person or Organization
belongs.

A member_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::ProgramMembership']>

=back

=head2 C<_has_member_of>

A predicate for the L</member_of> attribute.

=head2 C<naics>

The North American Industry Classification System (NAICS) code for a
particular organization or business person.

A naics should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_naics>

A predicate for the L</naics> attribute.

=head2 C<nationality>

Nationality of the person.

A nationality should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Country']>

=back

=head2 C<_has_nationality>

A predicate for the L</nationality> attribute.

=head2 C<net_worth>

C<netWorth>

The total financial value of the person as calculated by subtracting assets
from liabilities.

A net_worth should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=item C<InstanceOf['SemanticWeb::Schema::PriceSpecification']>

=back

=head2 C<_has_net_worth>

A predicate for the L</net_worth> attribute.

=head2 C<owns>

Products owned by the organization or person.

A owns should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::OwnershipInfo']>

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=back

=head2 C<_has_owns>

A predicate for the L</owns> attribute.

=head2 C<parent>

A parent of this person.

A parent should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_parent>

A predicate for the L</parent> attribute.

=head2 C<parents>

A parents of the person.

A parents should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_parents>

A predicate for the L</parents> attribute.

=head2 C<performer_in>

C<performerIn>

Event that this person is a performer or participant in.

A performer_in should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Event']>

=back

=head2 C<_has_performer_in>

A predicate for the L</performer_in> attribute.

=head2 C<publishing_principles>

C<publishingPrinciples>

=for html <p>The publishingPrinciples property indicates (typically via <a
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
schema.org terminology.<p>

A publishing_principles should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_publishing_principles>

A predicate for the L</publishing_principles> attribute.

=head2 C<related_to>

C<relatedTo>

The most generic familial relation.

A related_to should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_related_to>

A predicate for the L</related_to> attribute.

=head2 C<seeks>

A pointer to products or services sought by the organization or person
(demand).

A seeks should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Demand']>

=back

=head2 C<_has_seeks>

A predicate for the L</seeks> attribute.

=head2 C<sibling>

A sibling of the person.

A sibling should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_sibling>

A predicate for the L</sibling> attribute.

=head2 C<siblings>

A sibling of the person.

A siblings should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_siblings>

A predicate for the L</siblings> attribute.

=head2 C<sponsor>

A person or organization that supports a thing through a pledge, promise,
or financial contribution. e.g. a sponsor of a Medical Study or a corporate
sponsor of an event.

A sponsor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_sponsor>

A predicate for the L</sponsor> attribute.

=head2 C<spouse>

The person's spouse.

A spouse should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_spouse>

A predicate for the L</spouse> attribute.

=head2 C<tax_id>

C<taxID>

The Tax / Fiscal ID of the organization or person, e.g. the TIN in the US
or the CIF/NIF in Spain.

A tax_id should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_tax_id>

A predicate for the L</tax_id> attribute.

=head2 C<telephone>

The telephone number.

A telephone should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_telephone>

A predicate for the L</telephone> attribute.

=head2 C<vat_id>

C<vatID>

The Value-added Tax ID of the organization or person.

A vat_id should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_vat_id>

A predicate for the L</vat_id> attribute.

=head2 C<weight>

The weight of the product or person.

A weight should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_weight>

A predicate for the L</weight> attribute.

=head2 C<work_location>

C<workLocation>

A contact location for a person's place of work.

A work_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_work_location>

A predicate for the L</work_location> attribute.

=head2 C<works_for>

C<worksFor>

Organizations that the person works for.

A works_for should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_works_for>

A predicate for the L</works_for> attribute.

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
