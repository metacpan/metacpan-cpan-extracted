use utf8;

package SemanticWeb::Schema::SpecialAnnouncement;

# ABSTRACT: A SpecialAnnouncement combines a simple date-stamped textual information update with contextualized Web links and other structured data

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'SpecialAnnouncement';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has announcement_location => (
    is        => 'rw',
    predicate => '_has_announcement_location',
    json_ld   => 'announcementLocation',
);



has category => (
    is        => 'rw',
    predicate => '_has_category',
    json_ld   => 'category',
);



has date_posted => (
    is        => 'rw',
    predicate => '_has_date_posted',
    json_ld   => 'datePosted',
);



has disease_prevention_info => (
    is        => 'rw',
    predicate => '_has_disease_prevention_info',
    json_ld   => 'diseasePreventionInfo',
);



has disease_spread_statistics => (
    is        => 'rw',
    predicate => '_has_disease_spread_statistics',
    json_ld   => 'diseaseSpreadStatistics',
);



has getting_tested_info => (
    is        => 'rw',
    predicate => '_has_getting_tested_info',
    json_ld   => 'gettingTestedInfo',
);



has news_updates_and_guidelines => (
    is        => 'rw',
    predicate => '_has_news_updates_and_guidelines',
    json_ld   => 'newsUpdatesAndGuidelines',
);



has public_transport_closures_info => (
    is        => 'rw',
    predicate => '_has_public_transport_closures_info',
    json_ld   => 'publicTransportClosuresInfo',
);



has quarantine_guidelines => (
    is        => 'rw',
    predicate => '_has_quarantine_guidelines',
    json_ld   => 'quarantineGuidelines',
);



has school_closures_info => (
    is        => 'rw',
    predicate => '_has_school_closures_info',
    json_ld   => 'schoolClosuresInfo',
);



has travel_bans => (
    is        => 'rw',
    predicate => '_has_travel_bans',
    json_ld   => 'travelBans',
);



has web_feed => (
    is        => 'rw',
    predicate => '_has_web_feed',
    json_ld   => 'webFeed',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::SpecialAnnouncement - A SpecialAnnouncement combines a simple date-stamped textual information update with contextualized Web links and other structured data

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

=for html <p>A SpecialAnnouncement combines a simple date-stamped textual information
update with contextualized Web links and other structured data. It
represents an information update made by a locally-oriented organization,
for example schools, pharmacies, healthcare providers, community groups,
police, local government.<br/><br/> For work in progress guidelines on
Coronavirus-related markup see <a
href="https://docs.google.com/document/d/14ikaGCKxo50rRM7nvKSlbUpjyIk2WMQd3
IkB1lItlrM/edit#">this doc</a>.<br/><br/> The motivating scenario for
SpecialAnnouncement is the <a
href="https://en.wikipedia.org/wiki/2019%E2%80%9320_coronavirus_pandemic">C
oronavirus pandemic</a>, and the initial vocabulary is oriented to this
urgent situation. Schema.org expect to improve the markup iteratively as it
is deployed and as feedback emerges from use. In addition to our usual <a
href="https://github.com/schemaorg/schemaorg/issues/2490">Github entry</a>,
feedback comments can also be provided in <a
href="https://docs.google.com/document/d/1fpdFFxk8s87CWwACs53SGkYv3aafSxz_D
TtOQxMrBJQ/edit#">this document</a>.<br/><br/> While this schema is
designed to communicate urgent crisis-related information, it is not the
same as an emergency warning technology like <a
href="https://en.wikipedia.org/wiki/Common_Alerting_Protocol">CAP</a>,
although there may be overlaps. The intent is to cover the kinds of
everyday practical information being posted to existing websites during an
emergency situation.<br/><br/> Several kinds of information can be
provided:<br/><br/> We encourage the provision of "name", "text",
"datePosted", "expires" (if appropriate), "category" and "url" as a simple
baseline. It is important to provide a value for "category" where possible,
most ideally as a well known URL from Wikipedia or Wikidata. In the case of
the 2019-2020 Coronavirus pandemic, this should be
"https://en.wikipedia.org/w/index.php?title=2019-20_coronavirus_pandemic"
or "https://www.wikidata.org/wiki/Q81068910".<br/><br/> For many of the
possible properties, values can either be simple links or an inline
description, depending on whether a summary is available. For a link,
provide just the URL of the appropriate page as the property's value. For
an inline description, use a <a class="localLink"
href="http://schema.org/WebContent">WebContent</a> type, and provide the
url as a property of that, alongside at least a simple "<a
class="localLink" href="http://schema.org/text">text</a>" summary of the
page. It is unlikely that a single SpecialAnnouncement will need all of the
possible properties simultaneously.<br/><br/> We expect that in many cases
the page referenced might contain more specialized structured data, e.g.
contact info, <a class="localLink"
href="http://schema.org/openingHours">openingHours</a>, <a
class="localLink" href="http://schema.org/Event">Event</a>, <a
class="localLink" href="http://schema.org/FAQPage">FAQPage</a> etc. By
linking to those pages from a <a class="localLink"
href="http://schema.org/SpecialAnnouncement">SpecialAnnouncement</a> you
can help make it clearer that the events are related to the situation (e.g.
Coronavirus) indicated by the <a class="localLink"
href="http://schema.org/category">category</a> property of the <a
class="localLink"
href="http://schema.org/SpecialAnnouncement">SpecialAnnouncement</a>.<br/><
br/> Many <a class="localLink"
href="http://schema.org/SpecialAnnouncement">SpecialAnnouncement</a>s will
relate to particular regions and to identifiable local organizations. Use
<a class="localLink"
href="http://schema.org/spatialCoverage">spatialCoverage</a> for the
region, and <a class="localLink"
href="http://schema.org/announcementLocation">announcementLocation</a> to
indicate specific <a class="localLink"
href="http://schema.org/LocalBusiness">LocalBusiness</a>es and <a
class="localLink"
href="http://schema.org/CivicStructures">CivicStructures</a>. If the
announcement affects both a particular region and a specific location (for
example, a library closure that serves an entire region), use both <a
class="localLink"
href="http://schema.org/spatialCoverage">spatialCoverage</a> and <a
class="localLink"
href="http://schema.org/announcementLocation">announcementLocation</a>.<br/
><br/> The <a class="localLink" href="http://schema.org/about">about</a>
property can be used to indicate entities that are the focus of the
announcement. We now recommend using <a class="localLink"
href="http://schema.org/about">about</a> only for representing non-location
entities (e.g. a <a class="localLink"
href="http://schema.org/Course">Course</a> or a <a class="localLink"
href="http://schema.org/RadioStation">RadioStation</a>). For places, use <a
class="localLink"
href="http://schema.org/announcementLocation">announcementLocation</a> and
<a class="localLink"
href="http://schema.org/spatialCoverage">spatialCoverage</a>. Consumers of
this markup should be aware that the initial design encouraged the use of
/about for locations too.<br/><br/> The basic content of <a
class="localLink"
href="http://schema.org/SpecialAnnouncement">SpecialAnnouncement</a> is
similar to that of an <a href="https://en.wikipedia.org/wiki/RSS">RSS</a>
or <a href="https://en.wikipedia.org/wiki/Atom_(Web_standard)">Atom</a>
feed. For publishers without such feeds, basic feed-like information can be
shared by posting <a class="localLink"
href="http://schema.org/SpecialAnnouncement">SpecialAnnouncement</a>
updates in a page, e.g. using JSON-LD. For sites with Atom/RSS
functionality, you can point to a feed with the <a class="localLink"
href="http://schema.org/webFeed">webFeed</a> property. This can be a simple
URL, or an inline <a class="localLink"
href="http://schema.org/DataFeed">DataFeed</a> object, with <a
class="localLink"
href="http://schema.org/encodingFormat">encodingFormat</a> providing media
type information e.g. "application/rss+xml" or "application/atom+xml".<p>

=head1 ATTRIBUTES

=head2 C<announcement_location>

C<announcementLocation>

=for html <p>Indicates a specific <a class="localLink"
href="http://schema.org/CivicStructure">CivicStructure</a> or <a
class="localLink" href="http://schema.org/LocalBusiness">LocalBusiness</a>
associated with the SpecialAnnouncement. For example, a specific testing
facility or business with special opening hours. For a larger geographic
region like a quarantine of an entire region, use <a class="localLink"
href="http://schema.org/spatialCoverage">spatialCoverage</a>.<p>

A announcement_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CivicStructure']>

=item C<InstanceOf['SemanticWeb::Schema::LocalBusiness']>

=back

=head2 C<_has_announcement_location>

A predicate for the L</announcement_location> attribute.

=head2 C<category>

A category for the item. Greater signs or slashes can be used to informally
indicate a category hierarchy.

A category should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PhysicalActivityCategory']>

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=item C<Str>

=back

=head2 C<_has_category>

A predicate for the L</category> attribute.

=head2 C<date_posted>

C<datePosted>

Publication date of an online listing.

A date_posted should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_date_posted>

A predicate for the L</date_posted> attribute.

=head2 C<disease_prevention_info>

C<diseasePreventionInfo>

Information about disease prevention.

A disease_prevention_info should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::WebContent']>

=item C<Str>

=back

=head2 C<_has_disease_prevention_info>

A predicate for the L</disease_prevention_info> attribute.

=head2 C<disease_spread_statistics>

C<diseaseSpreadStatistics>

=for html <p>Statistical information about the spread of a disease, either as <a
class="localLink" href="http://schema.org/WebContent">WebContent</a>, or
described directly as a <a class="localLink"
href="http://schema.org/Dataset">Dataset</a>, or the specific <a
class="localLink" href="http://schema.org/Observation">Observation</a>s in
the dataset. When a <a class="localLink"
href="http://schema.org/WebContent">WebContent</a> URL is provided, the
page indicated might also contain more such markup.<p>

A disease_spread_statistics should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Dataset']>

=item C<InstanceOf['SemanticWeb::Schema::Observation']>

=item C<InstanceOf['SemanticWeb::Schema::WebContent']>

=item C<Str>

=back

=head2 C<_has_disease_spread_statistics>

A predicate for the L</disease_spread_statistics> attribute.

=head2 C<getting_tested_info>

C<gettingTestedInfo>

=for html <p>Information about getting tested (for a <a class="localLink"
href="http://schema.org/MedicalCondition">MedicalCondition</a>), e.g. in
the context of a pandemic.<p>

A getting_tested_info should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::WebContent']>

=item C<Str>

=back

=head2 C<_has_getting_tested_info>

A predicate for the L</getting_tested_info> attribute.

=head2 C<news_updates_and_guidelines>

C<newsUpdatesAndGuidelines>

=for html <p>Indicates a page with news updates and guidelines. This could often be
(but is not required to be) the main page containing <a class="localLink"
href="http://schema.org/SpecialAnnouncement">SpecialAnnouncement</a> markup
on a site.<p>

A news_updates_and_guidelines should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::WebContent']>

=item C<Str>

=back

=head2 C<_has_news_updates_and_guidelines>

A predicate for the L</news_updates_and_guidelines> attribute.

=head2 C<public_transport_closures_info>

C<publicTransportClosuresInfo>

Information about public transport closures.

A public_transport_closures_info should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::WebContent']>

=item C<Str>

=back

=head2 C<_has_public_transport_closures_info>

A predicate for the L</public_transport_closures_info> attribute.

=head2 C<quarantine_guidelines>

C<quarantineGuidelines>

Guidelines about quarantine rules, e.g. in the context of a pandemic.

A quarantine_guidelines should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::WebContent']>

=item C<Str>

=back

=head2 C<_has_quarantine_guidelines>

A predicate for the L</quarantine_guidelines> attribute.

=head2 C<school_closures_info>

C<schoolClosuresInfo>

Information about school closures.

A school_closures_info should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::WebContent']>

=item C<Str>

=back

=head2 C<_has_school_closures_info>

A predicate for the L</school_closures_info> attribute.

=head2 C<travel_bans>

C<travelBans>

Information about travel bans, e.g. in the context of a pandemic.

A travel_bans should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::WebContent']>

=item C<Str>

=back

=head2 C<_has_travel_bans>

A predicate for the L</travel_bans> attribute.

=head2 C<web_feed>

C<webFeed>

The URL for a feed, e.g. associated with a podcast series, blog, or series
of date-stamped updates. This is usually RSS or Atom.

A web_feed should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DataFeed']>

=item C<Str>

=back

=head2 C<_has_web_feed>

A predicate for the L</web_feed> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

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
