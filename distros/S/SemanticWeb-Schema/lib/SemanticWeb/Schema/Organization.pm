use utf8;

package SemanticWeb::Schema::Organization;

# ABSTRACT: An organization such as a school

use Moo;

extends qw/ SemanticWeb::Schema::Thing /;


use MooX::JSON_LD 'Organization';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has actionable_feedback_policy => (
    is        => 'rw',
    predicate => '_has_actionable_feedback_policy',
    json_ld   => 'actionableFeedbackPolicy',
);



has address => (
    is        => 'rw',
    predicate => '_has_address',
    json_ld   => 'address',
);



has aggregate_rating => (
    is        => 'rw',
    predicate => '_has_aggregate_rating',
    json_ld   => 'aggregateRating',
);



has alumni => (
    is        => 'rw',
    predicate => '_has_alumni',
    json_ld   => 'alumni',
);



has area_served => (
    is        => 'rw',
    predicate => '_has_area_served',
    json_ld   => 'areaServed',
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



has brand => (
    is        => 'rw',
    predicate => '_has_brand',
    json_ld   => 'brand',
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



has corrections_policy => (
    is        => 'rw',
    predicate => '_has_corrections_policy',
    json_ld   => 'correctionsPolicy',
);



has department => (
    is        => 'rw',
    predicate => '_has_department',
    json_ld   => 'department',
);



has dissolution_date => (
    is        => 'rw',
    predicate => '_has_dissolution_date',
    json_ld   => 'dissolutionDate',
);



has diversity_policy => (
    is        => 'rw',
    predicate => '_has_diversity_policy',
    json_ld   => 'diversityPolicy',
);



has diversity_staffing_report => (
    is        => 'rw',
    predicate => '_has_diversity_staffing_report',
    json_ld   => 'diversityStaffingReport',
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



has employee => (
    is        => 'rw',
    predicate => '_has_employee',
    json_ld   => 'employee',
);



has employees => (
    is        => 'rw',
    predicate => '_has_employees',
    json_ld   => 'employees',
);



has ethics_policy => (
    is        => 'rw',
    predicate => '_has_ethics_policy',
    json_ld   => 'ethicsPolicy',
);



has event => (
    is        => 'rw',
    predicate => '_has_event',
    json_ld   => 'event',
);



has events => (
    is        => 'rw',
    predicate => '_has_events',
    json_ld   => 'events',
);



has fax_number => (
    is        => 'rw',
    predicate => '_has_fax_number',
    json_ld   => 'faxNumber',
);



has founder => (
    is        => 'rw',
    predicate => '_has_founder',
    json_ld   => 'founder',
);



has founders => (
    is        => 'rw',
    predicate => '_has_founders',
    json_ld   => 'founders',
);



has founding_date => (
    is        => 'rw',
    predicate => '_has_founding_date',
    json_ld   => 'foundingDate',
);



has founding_location => (
    is        => 'rw',
    predicate => '_has_founding_location',
    json_ld   => 'foundingLocation',
);



has funder => (
    is        => 'rw',
    predicate => '_has_funder',
    json_ld   => 'funder',
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



has has_merchant_return_policy => (
    is        => 'rw',
    predicate => '_has_has_merchant_return_policy',
    json_ld   => 'hasMerchantReturnPolicy',
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



has has_product_return_policy => (
    is        => 'rw',
    predicate => '_has_has_product_return_policy',
    json_ld   => 'hasProductReturnPolicy',
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



has legal_name => (
    is        => 'rw',
    predicate => '_has_legal_name',
    json_ld   => 'legalName',
);



has lei_code => (
    is        => 'rw',
    predicate => '_has_lei_code',
    json_ld   => 'leiCode',
);



has location => (
    is        => 'rw',
    predicate => '_has_location',
    json_ld   => 'location',
);



has logo => (
    is        => 'rw',
    predicate => '_has_logo',
    json_ld   => 'logo',
);



has makes_offer => (
    is        => 'rw',
    predicate => '_has_makes_offer',
    json_ld   => 'makesOffer',
);



has member => (
    is        => 'rw',
    predicate => '_has_member',
    json_ld   => 'member',
);



has member_of => (
    is        => 'rw',
    predicate => '_has_member_of',
    json_ld   => 'memberOf',
);



has members => (
    is        => 'rw',
    predicate => '_has_members',
    json_ld   => 'members',
);



has naics => (
    is        => 'rw',
    predicate => '_has_naics',
    json_ld   => 'naics',
);



has nonprofit_status => (
    is        => 'rw',
    predicate => '_has_nonprofit_status',
    json_ld   => 'nonprofitStatus',
);



has number_of_employees => (
    is        => 'rw',
    predicate => '_has_number_of_employees',
    json_ld   => 'numberOfEmployees',
);



has ownership_funding_info => (
    is        => 'rw',
    predicate => '_has_ownership_funding_info',
    json_ld   => 'ownershipFundingInfo',
);



has owns => (
    is        => 'rw',
    predicate => '_has_owns',
    json_ld   => 'owns',
);



has parent_organization => (
    is        => 'rw',
    predicate => '_has_parent_organization',
    json_ld   => 'parentOrganization',
);



has publishing_principles => (
    is        => 'rw',
    predicate => '_has_publishing_principles',
    json_ld   => 'publishingPrinciples',
);



has review => (
    is        => 'rw',
    predicate => '_has_review',
    json_ld   => 'review',
);



has reviews => (
    is        => 'rw',
    predicate => '_has_reviews',
    json_ld   => 'reviews',
);



has seeks => (
    is        => 'rw',
    predicate => '_has_seeks',
    json_ld   => 'seeks',
);



has service_area => (
    is        => 'rw',
    predicate => '_has_service_area',
    json_ld   => 'serviceArea',
);



has slogan => (
    is        => 'rw',
    predicate => '_has_slogan',
    json_ld   => 'slogan',
);



has sponsor => (
    is        => 'rw',
    predicate => '_has_sponsor',
    json_ld   => 'sponsor',
);



has sub_organization => (
    is        => 'rw',
    predicate => '_has_sub_organization',
    json_ld   => 'subOrganization',
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



has unnamed_sources_policy => (
    is        => 'rw',
    predicate => '_has_unnamed_sources_policy',
    json_ld   => 'unnamedSourcesPolicy',
);



has vat_id => (
    is        => 'rw',
    predicate => '_has_vat_id',
    json_ld   => 'vatID',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Organization - An organization such as a school

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

An organization such as a school, NGO, corporation, club, etc.

=head1 ATTRIBUTES

=head2 C<actionable_feedback_policy>

C<actionableFeedbackPolicy>

=for html <p>For a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a> or
other news-related <a class="localLink"
href="http://schema.org/Organization">Organization</a>, a statement about
public engagement activities (for news media, the newsroomâs), including
involving the public - digitally or otherwise -- in coverage decisions,
reporting and activities after publication.<p>

A actionable_feedback_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_actionable_feedback_policy>

A predicate for the L</actionable_feedback_policy> attribute.

=head2 C<address>

Physical address of the item.

A address should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PostalAddress']>

=item C<Str>

=back

=head2 C<_has_address>

A predicate for the L</address> attribute.

=head2 C<aggregate_rating>

C<aggregateRating>

The overall rating, based on a collection of reviews or ratings, of the
item.

A aggregate_rating should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AggregateRating']>

=back

=head2 C<_has_aggregate_rating>

A predicate for the L</aggregate_rating> attribute.

=head2 C<alumni>

Alumni of an organization.

A alumni should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_alumni>

A predicate for the L</alumni> attribute.

=head2 C<area_served>

C<areaServed>

The geographic area where a service or offered item is provided.

A area_served should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<Str>

=back

=head2 C<_has_area_served>

A predicate for the L</area_served> attribute.

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

=head2 C<corrections_policy>

C<correctionsPolicy>

=for html <p>For an <a class="localLink"
href="http://schema.org/Organization">Organization</a> (e.g. <a
class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>),
a statement describing (in news media, the newsroomâs) disclosure and
correction policy for errors.<p>

A corrections_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_corrections_policy>

A predicate for the L</corrections_policy> attribute.

=head2 C<department>

A relationship between an organization and a department of that
organization, also described as an organization (allowing different urls,
logos, opening hours). For example: a store with a pharmacy, or a bakery
with a cafe.

A department should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_department>

A predicate for the L</department> attribute.

=head2 C<dissolution_date>

C<dissolutionDate>

The date that this organization was dissolved.

A dissolution_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_dissolution_date>

A predicate for the L</dissolution_date> attribute.

=head2 C<diversity_policy>

C<diversityPolicy>

=for html <p>Statement on diversity policy by an <a class="localLink"
href="http://schema.org/Organization">Organization</a> e.g. a <a
class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>.
For a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>, a
statement describing the newsroomâs diversity policy on both staffing and
sources, typically providing staffing data.<p>

A diversity_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_diversity_policy>

A predicate for the L</diversity_policy> attribute.

=head2 C<diversity_staffing_report>

C<diversityStaffingReport>

=for html <p>For an <a class="localLink"
href="http://schema.org/Organization">Organization</a> (often but not
necessarily a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>),
a report on staffing diversity issues. In a news context this might be for
example ASNE or RTDNA (US) reports, or self-reported.<p>

A diversity_staffing_report should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Article']>

=item C<Str>

=back

=head2 C<_has_diversity_staffing_report>

A predicate for the L</diversity_staffing_report> attribute.

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

=head2 C<employee>

Someone working for this organization.

A employee should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_employee>

A predicate for the L</employee> attribute.

=head2 C<employees>

People working for this organization.

A employees should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_employees>

A predicate for the L</employees> attribute.

=head2 C<ethics_policy>

C<ethicsPolicy>

=for html <p>Statement about ethics policy, e.g. of a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>
regarding journalistic and publishing practices, or of a <a
class="localLink" href="http://schema.org/Restaurant">Restaurant</a>, a
page describing food source policies. In the case of a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>,
an ethicsPolicy is typically a statement describing the personal,
organizational, and corporate standards of behavior expected by the
organization.<p>

A ethics_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_ethics_policy>

A predicate for the L</ethics_policy> attribute.

=head2 C<event>

Upcoming or past event associated with this place, organization, or action.

A event should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Event']>

=back

=head2 C<_has_event>

A predicate for the L</event> attribute.

=head2 C<events>

Upcoming or past events associated with this place or organization.

A events should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Event']>

=back

=head2 C<_has_events>

A predicate for the L</events> attribute.

=head2 C<fax_number>

C<faxNumber>

The fax number.

A fax_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_fax_number>

A predicate for the L</fax_number> attribute.

=head2 C<founder>

A person who founded this organization.

A founder should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_founder>

A predicate for the L</founder> attribute.

=head2 C<founders>

A person who founded this organization.

A founders should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_founders>

A predicate for the L</founders> attribute.

=head2 C<founding_date>

C<foundingDate>

The date that this organization was founded.

A founding_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_founding_date>

A predicate for the L</founding_date> attribute.

=head2 C<founding_location>

C<foundingLocation>

The place where the Organization was founded.

A founding_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_founding_location>

A predicate for the L</founding_location> attribute.

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

=head2 C<has_merchant_return_policy>

C<hasMerchantReturnPolicy>

Indicates a MerchantReturnPolicy that may be applicable.

A has_merchant_return_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MerchantReturnPolicy']>

=back

=head2 C<_has_has_merchant_return_policy>

A predicate for the L</has_merchant_return_policy> attribute.

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

=head2 C<has_product_return_policy>

C<hasProductReturnPolicy>

Indicates a ProductReturnPolicy that may be applicable.

A has_product_return_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ProductReturnPolicy']>

=back

=head2 C<_has_has_product_return_policy>

A predicate for the L</has_product_return_policy> attribute.

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

=head2 C<legal_name>

C<legalName>

The official name of the organization, e.g. the registered company name.

A legal_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_legal_name>

A predicate for the L</legal_name> attribute.

=head2 C<lei_code>

C<leiCode>

An organization identifier that uniquely identifies a legal entity as
defined in ISO 17442.

A lei_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_lei_code>

A predicate for the L</lei_code> attribute.

=head2 C<location>

The location of for example where the event is happening, an organization
is located, or where an action takes place.

A location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<InstanceOf['SemanticWeb::Schema::PostalAddress']>

=item C<InstanceOf['SemanticWeb::Schema::VirtualLocation']>

=item C<Str>

=back

=head2 C<_has_location>

A predicate for the L</location> attribute.

=head2 C<logo>

An associated logo.

A logo should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ImageObject']>

=item C<Str>

=back

=head2 C<_has_logo>

A predicate for the L</logo> attribute.

=head2 C<makes_offer>

C<makesOffer>

A pointer to products or services offered by the organization or person.

A makes_offer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<_has_makes_offer>

A predicate for the L</makes_offer> attribute.

=head2 C<member>

A member of an Organization or a ProgramMembership. Organizations can be
members of organizations; ProgramMembership is typically for individuals.

A member should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_member>

A predicate for the L</member> attribute.

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

=head2 C<members>

A member of this organization.

A members should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_members>

A predicate for the L</members> attribute.

=head2 C<naics>

The North American Industry Classification System (NAICS) code for a
particular organization or business person.

A naics should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_naics>

A predicate for the L</naics> attribute.

=head2 C<nonprofit_status>

C<nonprofitStatus>

nonprofit Status indicates the legal status of a non-profit organization in
its primary place of business.

A nonprofit_status should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::NonprofitType']>

=back

=head2 C<_has_nonprofit_status>

A predicate for the L</nonprofit_status> attribute.

=head2 C<number_of_employees>

C<numberOfEmployees>

The number of employees in an organization e.g. business.

A number_of_employees should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_number_of_employees>

A predicate for the L</number_of_employees> attribute.

=head2 C<ownership_funding_info>

C<ownershipFundingInfo>

=for html <p>For an <a class="localLink"
href="http://schema.org/Organization">Organization</a> (often but not
necessarily a <a class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>),
a description of organizational ownership structure; funding and grants. In
a news/media setting, this is with particular reference to editorial
independence. Note that the <a class="localLink"
href="http://schema.org/funder">funder</a> is also available and can be
used to make basic funder information machine-readable.<p>

A ownership_funding_info should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AboutPage']>

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_ownership_funding_info>

A predicate for the L</ownership_funding_info> attribute.

=head2 C<owns>

Products owned by the organization or person.

A owns should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::OwnershipInfo']>

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=back

=head2 C<_has_owns>

A predicate for the L</owns> attribute.

=head2 C<parent_organization>

C<parentOrganization>

=for html <p>The larger organization that this organization is a <a class="localLink"
href="http://schema.org/subOrganization">subOrganization</a> of, if any.<p>

A parent_organization should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_parent_organization>

A predicate for the L</parent_organization> attribute.

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

=head2 C<review>

A review of the item.

A review should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Review']>

=back

=head2 C<_has_review>

A predicate for the L</review> attribute.

=head2 C<reviews>

Review of the item.

A reviews should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Review']>

=back

=head2 C<_has_reviews>

A predicate for the L</reviews> attribute.

=head2 C<seeks>

A pointer to products or services sought by the organization or person
(demand).

A seeks should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Demand']>

=back

=head2 C<_has_seeks>

A predicate for the L</seeks> attribute.

=head2 C<service_area>

C<serviceArea>

The geographic area where the service is provided.

A service_area should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_service_area>

A predicate for the L</service_area> attribute.

=head2 C<slogan>

A slogan or motto associated with the item.

A slogan should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_slogan>

A predicate for the L</slogan> attribute.

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

=head2 C<sub_organization>

C<subOrganization>

A relationship between two organizations where the first includes the
second, e.g., as a subsidiary. See also: the more specific 'department'
property.

A sub_organization should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_sub_organization>

A predicate for the L</sub_organization> attribute.

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

=head2 C<unnamed_sources_policy>

C<unnamedSourcesPolicy>

=for html <p>For an <a class="localLink"
href="http://schema.org/Organization">Organization</a> (typically a <a
class="localLink"
href="http://schema.org/NewsMediaOrganization">NewsMediaOrganization</a>),
a statement about policy on use of unnamed sources and the decision process
required.<p>

A unnamed_sources_policy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_unnamed_sources_policy>

A predicate for the L</unnamed_sources_policy> attribute.

=head2 C<vat_id>

C<vatID>

The Value-added Tax ID of the organization or person.

A vat_id should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_vat_id>

A predicate for the L</vat_id> attribute.

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
