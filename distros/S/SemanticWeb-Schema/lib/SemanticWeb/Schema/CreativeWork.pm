use utf8;

package SemanticWeb::Schema::CreativeWork;

# ABSTRACT: The most generic kind of creative work

use Moo;

extends qw/ SemanticWeb::Schema::Thing /;


use MooX::JSON_LD 'CreativeWork';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.2';


has about => (
    is        => 'rw',
    predicate => '_has_about',
    json_ld   => 'about',
);



has abstract => (
    is        => 'rw',
    predicate => '_has_abstract',
    json_ld   => 'abstract',
);



has access_mode => (
    is        => 'rw',
    predicate => '_has_access_mode',
    json_ld   => 'accessMode',
);



has access_mode_sufficient => (
    is        => 'rw',
    predicate => '_has_access_mode_sufficient',
    json_ld   => 'accessModeSufficient',
);



has accessibility_api => (
    is        => 'rw',
    predicate => '_has_accessibility_api',
    json_ld   => 'accessibilityAPI',
);



has accessibility_control => (
    is        => 'rw',
    predicate => '_has_accessibility_control',
    json_ld   => 'accessibilityControl',
);



has accessibility_feature => (
    is        => 'rw',
    predicate => '_has_accessibility_feature',
    json_ld   => 'accessibilityFeature',
);



has accessibility_hazard => (
    is        => 'rw',
    predicate => '_has_accessibility_hazard',
    json_ld   => 'accessibilityHazard',
);



has accessibility_summary => (
    is        => 'rw',
    predicate => '_has_accessibility_summary',
    json_ld   => 'accessibilitySummary',
);



has accountable_person => (
    is        => 'rw',
    predicate => '_has_accountable_person',
    json_ld   => 'accountablePerson',
);



has acquire_license_page => (
    is        => 'rw',
    predicate => '_has_acquire_license_page',
    json_ld   => 'acquireLicensePage',
);



has aggregate_rating => (
    is        => 'rw',
    predicate => '_has_aggregate_rating',
    json_ld   => 'aggregateRating',
);



has alternative_headline => (
    is        => 'rw',
    predicate => '_has_alternative_headline',
    json_ld   => 'alternativeHeadline',
);



has associated_media => (
    is        => 'rw',
    predicate => '_has_associated_media',
    json_ld   => 'associatedMedia',
);



has audience => (
    is        => 'rw',
    predicate => '_has_audience',
    json_ld   => 'audience',
);



has audio => (
    is        => 'rw',
    predicate => '_has_audio',
    json_ld   => 'audio',
);



has author => (
    is        => 'rw',
    predicate => '_has_author',
    json_ld   => 'author',
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



has character => (
    is        => 'rw',
    predicate => '_has_character',
    json_ld   => 'character',
);



has citation => (
    is        => 'rw',
    predicate => '_has_citation',
    json_ld   => 'citation',
);



has comment => (
    is        => 'rw',
    predicate => '_has_comment',
    json_ld   => 'comment',
);



has comment_count => (
    is        => 'rw',
    predicate => '_has_comment_count',
    json_ld   => 'commentCount',
);



has conditions_of_access => (
    is        => 'rw',
    predicate => '_has_conditions_of_access',
    json_ld   => 'conditionsOfAccess',
);



has content_location => (
    is        => 'rw',
    predicate => '_has_content_location',
    json_ld   => 'contentLocation',
);



has content_rating => (
    is        => 'rw',
    predicate => '_has_content_rating',
    json_ld   => 'contentRating',
);



has content_reference_time => (
    is        => 'rw',
    predicate => '_has_content_reference_time',
    json_ld   => 'contentReferenceTime',
);



has contributor => (
    is        => 'rw',
    predicate => '_has_contributor',
    json_ld   => 'contributor',
);



has copyright_holder => (
    is        => 'rw',
    predicate => '_has_copyright_holder',
    json_ld   => 'copyrightHolder',
);



has copyright_year => (
    is        => 'rw',
    predicate => '_has_copyright_year',
    json_ld   => 'copyrightYear',
);



has correction => (
    is        => 'rw',
    predicate => '_has_correction',
    json_ld   => 'correction',
);



has creative_work_status => (
    is        => 'rw',
    predicate => '_has_creative_work_status',
    json_ld   => 'creativeWorkStatus',
);



has creator => (
    is        => 'rw',
    predicate => '_has_creator',
    json_ld   => 'creator',
);



has date_created => (
    is        => 'rw',
    predicate => '_has_date_created',
    json_ld   => 'dateCreated',
);



has date_modified => (
    is        => 'rw',
    predicate => '_has_date_modified',
    json_ld   => 'dateModified',
);



has date_published => (
    is        => 'rw',
    predicate => '_has_date_published',
    json_ld   => 'datePublished',
);



has discussion_url => (
    is        => 'rw',
    predicate => '_has_discussion_url',
    json_ld   => 'discussionUrl',
);



has editor => (
    is        => 'rw',
    predicate => '_has_editor',
    json_ld   => 'editor',
);



has educational_alignment => (
    is        => 'rw',
    predicate => '_has_educational_alignment',
    json_ld   => 'educationalAlignment',
);



has educational_use => (
    is        => 'rw',
    predicate => '_has_educational_use',
    json_ld   => 'educationalUse',
);



has encoding => (
    is        => 'rw',
    predicate => '_has_encoding',
    json_ld   => 'encoding',
);



has encoding_format => (
    is        => 'rw',
    predicate => '_has_encoding_format',
    json_ld   => 'encodingFormat',
);



has encodings => (
    is        => 'rw',
    predicate => '_has_encodings',
    json_ld   => 'encodings',
);



has example_of_work => (
    is        => 'rw',
    predicate => '_has_example_of_work',
    json_ld   => 'exampleOfWork',
);



has expires => (
    is        => 'rw',
    predicate => '_has_expires',
    json_ld   => 'expires',
);



has file_format => (
    is        => 'rw',
    predicate => '_has_file_format',
    json_ld   => 'fileFormat',
);



has funder => (
    is        => 'rw',
    predicate => '_has_funder',
    json_ld   => 'funder',
);



has genre => (
    is        => 'rw',
    predicate => '_has_genre',
    json_ld   => 'genre',
);



has has_part => (
    is        => 'rw',
    predicate => '_has_has_part',
    json_ld   => 'hasPart',
);



has headline => (
    is        => 'rw',
    predicate => '_has_headline',
    json_ld   => 'headline',
);



has in_language => (
    is        => 'rw',
    predicate => '_has_in_language',
    json_ld   => 'inLanguage',
);



has interaction_statistic => (
    is        => 'rw',
    predicate => '_has_interaction_statistic',
    json_ld   => 'interactionStatistic',
);



has interactivity_type => (
    is        => 'rw',
    predicate => '_has_interactivity_type',
    json_ld   => 'interactivityType',
);



has is_accessible_for_free => (
    is        => 'rw',
    predicate => '_has_is_accessible_for_free',
    json_ld   => 'isAccessibleForFree',
);



has is_based_on => (
    is        => 'rw',
    predicate => '_has_is_based_on',
    json_ld   => 'isBasedOn',
);



has is_based_on_url => (
    is        => 'rw',
    predicate => '_has_is_based_on_url',
    json_ld   => 'isBasedOnUrl',
);



has is_family_friendly => (
    is        => 'rw',
    predicate => '_has_is_family_friendly',
    json_ld   => 'isFamilyFriendly',
);



has is_part_of => (
    is        => 'rw',
    predicate => '_has_is_part_of',
    json_ld   => 'isPartOf',
);



has keywords => (
    is        => 'rw',
    predicate => '_has_keywords',
    json_ld   => 'keywords',
);



has learning_resource_type => (
    is        => 'rw',
    predicate => '_has_learning_resource_type',
    json_ld   => 'learningResourceType',
);



has license => (
    is        => 'rw',
    predicate => '_has_license',
    json_ld   => 'license',
);



has location_created => (
    is        => 'rw',
    predicate => '_has_location_created',
    json_ld   => 'locationCreated',
);



has main_entity => (
    is        => 'rw',
    predicate => '_has_main_entity',
    json_ld   => 'mainEntity',
);



has maintainer => (
    is        => 'rw',
    predicate => '_has_maintainer',
    json_ld   => 'maintainer',
);



has material => (
    is        => 'rw',
    predicate => '_has_material',
    json_ld   => 'material',
);



has mentions => (
    is        => 'rw',
    predicate => '_has_mentions',
    json_ld   => 'mentions',
);



has offers => (
    is        => 'rw',
    predicate => '_has_offers',
    json_ld   => 'offers',
);



has position => (
    is        => 'rw',
    predicate => '_has_position',
    json_ld   => 'position',
);



has producer => (
    is        => 'rw',
    predicate => '_has_producer',
    json_ld   => 'producer',
);



has provider => (
    is        => 'rw',
    predicate => '_has_provider',
    json_ld   => 'provider',
);



has publication => (
    is        => 'rw',
    predicate => '_has_publication',
    json_ld   => 'publication',
);



has publisher => (
    is        => 'rw',
    predicate => '_has_publisher',
    json_ld   => 'publisher',
);



has publisher_imprint => (
    is        => 'rw',
    predicate => '_has_publisher_imprint',
    json_ld   => 'publisherImprint',
);



has publishing_principles => (
    is        => 'rw',
    predicate => '_has_publishing_principles',
    json_ld   => 'publishingPrinciples',
);



has recorded_at => (
    is        => 'rw',
    predicate => '_has_recorded_at',
    json_ld   => 'recordedAt',
);



has released_event => (
    is        => 'rw',
    predicate => '_has_released_event',
    json_ld   => 'releasedEvent',
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



has schema_version => (
    is        => 'rw',
    predicate => '_has_schema_version',
    json_ld   => 'schemaVersion',
);



has sd_date_published => (
    is        => 'rw',
    predicate => '_has_sd_date_published',
    json_ld   => 'sdDatePublished',
);



has sd_license => (
    is        => 'rw',
    predicate => '_has_sd_license',
    json_ld   => 'sdLicense',
);



has sd_publisher => (
    is        => 'rw',
    predicate => '_has_sd_publisher',
    json_ld   => 'sdPublisher',
);



has source_organization => (
    is        => 'rw',
    predicate => '_has_source_organization',
    json_ld   => 'sourceOrganization',
);



has spatial => (
    is        => 'rw',
    predicate => '_has_spatial',
    json_ld   => 'spatial',
);



has spatial_coverage => (
    is        => 'rw',
    predicate => '_has_spatial_coverage',
    json_ld   => 'spatialCoverage',
);



has sponsor => (
    is        => 'rw',
    predicate => '_has_sponsor',
    json_ld   => 'sponsor',
);



has temporal => (
    is        => 'rw',
    predicate => '_has_temporal',
    json_ld   => 'temporal',
);



has temporal_coverage => (
    is        => 'rw',
    predicate => '_has_temporal_coverage',
    json_ld   => 'temporalCoverage',
);



has text => (
    is        => 'rw',
    predicate => '_has_text',
    json_ld   => 'text',
);



has thumbnail_url => (
    is        => 'rw',
    predicate => '_has_thumbnail_url',
    json_ld   => 'thumbnailUrl',
);



has time_required => (
    is        => 'rw',
    predicate => '_has_time_required',
    json_ld   => 'timeRequired',
);



has translation_of_work => (
    is        => 'rw',
    predicate => '_has_translation_of_work',
    json_ld   => 'translationOfWork',
);



has translator => (
    is        => 'rw',
    predicate => '_has_translator',
    json_ld   => 'translator',
);



has typical_age_range => (
    is        => 'rw',
    predicate => '_has_typical_age_range',
    json_ld   => 'typicalAgeRange',
);



has usage_info => (
    is        => 'rw',
    predicate => '_has_usage_info',
    json_ld   => 'usageInfo',
);



has version => (
    is        => 'rw',
    predicate => '_has_version',
    json_ld   => 'version',
);



has video => (
    is        => 'rw',
    predicate => '_has_video',
    json_ld   => 'video',
);



has work_example => (
    is        => 'rw',
    predicate => '_has_work_example',
    json_ld   => 'workExample',
);



has work_translation => (
    is        => 'rw',
    predicate => '_has_work_translation',
    json_ld   => 'workTranslation',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CreativeWork - The most generic kind of creative work

=head1 VERSION

version v7.0.2

=head1 DESCRIPTION

The most generic kind of creative work, including books, movies,
photographs, software programs, etc.

=head1 ATTRIBUTES

=head2 C<about>

The subject matter of the content.

A about should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<_has_about>

A predicate for the L</about> attribute.

=head2 C<abstract>

=for html <p>An abstract is a short description that summarizes a <a
class="localLink"
href="http://schema.org/CreativeWork">CreativeWork</a>.<p>

A abstract should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_abstract>

A predicate for the L</abstract> attribute.

=head2 C<access_mode>

C<accessMode>

The human sensory perceptual system or cognitive faculty through which a
person may process or perceive information. Expected values include:
auditory, tactile, textual, visual, colorDependent, chartOnVisual,
chemOnVisual, diagramOnVisual, mathOnVisual, musicOnVisual, textOnVisual.

A access_mode should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_access_mode>

A predicate for the L</access_mode> attribute.

=head2 C<access_mode_sufficient>

C<accessModeSufficient>

A list of single or combined accessModes that are sufficient to understand
all the intellectual content of a resource. Expected values include:
auditory, tactile, textual, visual.

A access_mode_sufficient should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ItemList']>

=back

=head2 C<_has_access_mode_sufficient>

A predicate for the L</access_mode_sufficient> attribute.

=head2 C<accessibility_api>

C<accessibilityAPI>

=for html <p>Indicates that the resource is compatible with the referenced
accessibility API (<a
href="http://www.w3.org/wiki/WebSchemas/Accessibility">WebSchemas wiki
lists possible values</a>).<p>

A accessibility_api should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_accessibility_api>

A predicate for the L</accessibility_api> attribute.

=head2 C<accessibility_control>

C<accessibilityControl>

=for html <p>Identifies input methods that are sufficient to fully control the
described resource (<a
href="http://www.w3.org/wiki/WebSchemas/Accessibility">WebSchemas wiki
lists possible values</a>).<p>

A accessibility_control should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_accessibility_control>

A predicate for the L</accessibility_control> attribute.

=head2 C<accessibility_feature>

C<accessibilityFeature>

=for html <p>Content features of the resource, such as accessible media, alternatives
and supported enhancements for accessibility (<a
href="http://www.w3.org/wiki/WebSchemas/Accessibility">WebSchemas wiki
lists possible values</a>).<p>

A accessibility_feature should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_accessibility_feature>

A predicate for the L</accessibility_feature> attribute.

=head2 C<accessibility_hazard>

C<accessibilityHazard>

=for html <p>A characteristic of the described resource that is physiologically
dangerous to some users. Related to WCAG 2.0 guideline 2.3 (<a
href="http://www.w3.org/wiki/WebSchemas/Accessibility">WebSchemas wiki
lists possible values</a>).<p>

A accessibility_hazard should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_accessibility_hazard>

A predicate for the L</accessibility_hazard> attribute.

=head2 C<accessibility_summary>

C<accessibilitySummary>

A human-readable summary of specific accessibility features or
deficiencies, consistent with the other accessibility metadata but
expressing subtleties such as "short descriptions are present but long
descriptions will be needed for non-visual users" or "short descriptions
are present and no long descriptions are needed."

A accessibility_summary should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_accessibility_summary>

A predicate for the L</accessibility_summary> attribute.

=head2 C<accountable_person>

C<accountablePerson>

Specifies the Person that is legally accountable for the CreativeWork.

A accountable_person should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_accountable_person>

A predicate for the L</accountable_person> attribute.

=head2 C<acquire_license_page>

C<acquireLicensePage>

Indicates a page documenting how licenses can be purchased or otherwise
acquired, for the current item.

A acquire_license_page should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_acquire_license_page>

A predicate for the L</acquire_license_page> attribute.

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

=head2 C<alternative_headline>

C<alternativeHeadline>

A secondary title of the CreativeWork.

A alternative_headline should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_alternative_headline>

A predicate for the L</alternative_headline> attribute.

=head2 C<associated_media>

C<associatedMedia>

A media object that encodes this CreativeWork. This property is a synonym
for encoding.

A associated_media should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MediaObject']>

=back

=head2 C<_has_associated_media>

A predicate for the L</associated_media> attribute.

=head2 C<audience>

An intended audience, i.e. a group for whom something was created.

A audience should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Audience']>

=back

=head2 C<_has_audience>

A predicate for the L</audience> attribute.

=head2 C<audio>

An embedded audio object.

A audio should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AudioObject']>

=item C<InstanceOf['SemanticWeb::Schema::Clip']>

=item C<InstanceOf['SemanticWeb::Schema::MusicRecording']>

=back

=head2 C<_has_audio>

A predicate for the L</audio> attribute.

=head2 C<author>

The author of this content or rating. Please note that author is special in
that HTML 5 provides a special mechanism for indicating authorship via the
rel tag. That is equivalent to this and may be used interchangeably.

A author should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_author>

A predicate for the L</author> attribute.

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

=head2 C<character>

Fictional person connected with a creative work.

A character should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_character>

A predicate for the L</character> attribute.

=head2 C<citation>

A citation or reference to another creative work, such as another
publication, web page, scholarly article, etc.

A citation should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_citation>

A predicate for the L</citation> attribute.

=head2 C<comment>

Comments, typically from users.

A comment should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Comment']>

=back

=head2 C<_has_comment>

A predicate for the L</comment> attribute.

=head2 C<comment_count>

C<commentCount>

The number of comments this CreativeWork (e.g. Article, Question or Answer)
has received. This is most applicable to works published in Web sites with
commenting system; additional comments may exist elsewhere.

A comment_count should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_comment_count>

A predicate for the L</comment_count> attribute.

=head2 C<conditions_of_access>

C<conditionsOfAccess>

=for html <p>Conditions that affect the availability of, or method(s) of access to,
an item. Typically used for real world items such as an <a
class="localLink"
href="http://schema.org/ArchiveComponent">ArchiveComponent</a> held by an
<a class="localLink"
href="http://schema.org/ArchiveOrganization">ArchiveOrganization</a>. This
property is not suitable for use as a general Web access control mechanism.
It is expressed only in natural language.<br/><br/> For example "Available
by appointment from the Reading Room" or "Accessible only from logged-in
accounts ".<p>

A conditions_of_access should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_conditions_of_access>

A predicate for the L</conditions_of_access> attribute.

=head2 C<content_location>

C<contentLocation>

The location depicted or described in the content. For example, the
location in a photograph or painting.

A content_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_content_location>

A predicate for the L</content_location> attribute.

=head2 C<content_rating>

C<contentRating>

Official rating of a piece of content&#x2014;for example,'MPAA PG-13'.

A content_rating should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Rating']>

=item C<Str>

=back

=head2 C<_has_content_rating>

A predicate for the L</content_rating> attribute.

=head2 C<content_reference_time>

C<contentReferenceTime>

The specific time described by a creative work, for works (e.g. articles,
video objects etc.) that emphasise a particular moment within an Event.

A content_reference_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_content_reference_time>

A predicate for the L</content_reference_time> attribute.

=head2 C<contributor>

A secondary contributor to the CreativeWork or Event.

A contributor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_contributor>

A predicate for the L</contributor> attribute.

=head2 C<copyright_holder>

C<copyrightHolder>

The party holding the legal copyright to the CreativeWork.

A copyright_holder should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_copyright_holder>

A predicate for the L</copyright_holder> attribute.

=head2 C<copyright_year>

C<copyrightYear>

The year during which the claimed copyright for the CreativeWork was first
asserted.

A copyright_year should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_copyright_year>

A predicate for the L</copyright_year> attribute.

=head2 C<correction>

=for html <p>Indicates a correction to a <a class="localLink"
href="http://schema.org/CreativeWork">CreativeWork</a>, either via a <a
class="localLink"
href="http://schema.org/CorrectionComment">CorrectionComment</a>, textually
or in another document.<p>

A correction should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CorrectionComment']>

=item C<Str>

=back

=head2 C<_has_correction>

A predicate for the L</correction> attribute.

=head2 C<creative_work_status>

C<creativeWorkStatus>

The status of a creative work in terms of its stage in a lifecycle. Example
terms include Incomplete, Draft, Published, Obsolete. Some organizations
define a set of terms for the stages of their publication lifecycle.

A creative_work_status should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DefinedTerm']>

=item C<Str>

=back

=head2 C<_has_creative_work_status>

A predicate for the L</creative_work_status> attribute.

=head2 C<creator>

The creator/author of this CreativeWork. This is the same as the Author
property for CreativeWork.

A creator should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_creator>

A predicate for the L</creator> attribute.

=head2 C<date_created>

C<dateCreated>

The date on which the CreativeWork was created or the item was added to a
DataFeed.

A date_created should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_date_created>

A predicate for the L</date_created> attribute.

=head2 C<date_modified>

C<dateModified>

The date on which the CreativeWork was most recently modified or when the
item's entry was modified within a DataFeed.

A date_modified should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_date_modified>

A predicate for the L</date_modified> attribute.

=head2 C<date_published>

C<datePublished>

Date of first broadcast/publication.

A date_published should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_date_published>

A predicate for the L</date_published> attribute.

=head2 C<discussion_url>

C<discussionUrl>

A link to the page containing the comments of the CreativeWork.

A discussion_url should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_discussion_url>

A predicate for the L</discussion_url> attribute.

=head2 C<editor>

Specifies the Person who edited the CreativeWork.

A editor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_editor>

A predicate for the L</editor> attribute.

=head2 C<educational_alignment>

C<educationalAlignment>

An alignment to an established educational framework.

A educational_alignment should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AlignmentObject']>

=back

=head2 C<_has_educational_alignment>

A predicate for the L</educational_alignment> attribute.

=head2 C<educational_use>

C<educationalUse>

The purpose of a work in the context of education; for example,
'assignment', 'group work'.

A educational_use should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_educational_use>

A predicate for the L</educational_use> attribute.

=head2 C<encoding>

A media object that encodes this CreativeWork. This property is a synonym
for associatedMedia.

A encoding should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MediaObject']>

=back

=head2 C<_has_encoding>

A predicate for the L</encoding> attribute.

=head2 C<encoding_format>

C<encodingFormat>

=for html <p>Media type typically expressed using a MIME format (see <a
href="http://www.iana.org/assignments/media-types/media-types.xhtml">IANA
site</a> and <a
href="https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME
_types">MDN reference</a>) e.g. application/zip for a SoftwareApplication
binary, audio/mpeg for .mp3 etc.).<br/><br/> In cases where a <a
class="localLink" href="http://schema.org/CreativeWork">CreativeWork</a>
has several media type representations, <a class="localLink"
href="http://schema.org/encoding">encoding</a> can be used to indicate each
<a class="localLink" href="http://schema.org/MediaObject">MediaObject</a>
alongside particular <a class="localLink"
href="http://schema.org/encodingFormat">encodingFormat</a>
information.<br/><br/> Unregistered or niche encoding and file formats can
be indicated instead via the most appropriate URL, e.g. defining Web page
or a Wikipedia/Wikidata entry.<p>

A encoding_format should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_encoding_format>

A predicate for the L</encoding_format> attribute.

=head2 C<encodings>

A media object that encodes this CreativeWork.

A encodings should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MediaObject']>

=back

=head2 C<_has_encodings>

A predicate for the L</encodings> attribute.

=head2 C<example_of_work>

C<exampleOfWork>

A creative work that this work is an
example/instance/realization/derivation of.

A example_of_work should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=back

=head2 C<_has_example_of_work>

A predicate for the L</example_of_work> attribute.

=head2 C<expires>

=for html <p>Date the content expires and is no longer useful or available. For
example a <a class="localLink"
href="http://schema.org/VideoObject">VideoObject</a> or <a
class="localLink" href="http://schema.org/NewsArticle">NewsArticle</a>
whose availability or relevance is time-limited, or a <a class="localLink"
href="http://schema.org/ClaimReview">ClaimReview</a> fact check whose
publisher wants to indicate that it may no longer be relevant (or helpful
to highlight) after some date.<p>

A expires should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_expires>

A predicate for the L</expires> attribute.

=head2 C<file_format>

C<fileFormat>

=for html <p>Media type, typically MIME format (see <a
href="http://www.iana.org/assignments/media-types/media-types.xhtml">IANA
site</a>) of the content e.g. application/zip of a SoftwareApplication
binary. In cases where a CreativeWork has several media type
representations, 'encoding' can be used to indicate each MediaObject
alongside particular fileFormat information. Unregistered or niche file
formats can be indicated instead via the most appropriate URL, e.g.
defining Web page or a Wikipedia entry.<p>

A file_format should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_file_format>

A predicate for the L</file_format> attribute.

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

=head2 C<genre>

Genre of the creative work, broadcast channel or group.

A genre should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_genre>

A predicate for the L</genre> attribute.

=head2 C<has_part>

C<hasPart>

Indicates an item or CreativeWork that is part of this item, or
CreativeWork (in some sense).

A has_part should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=back

=head2 C<_has_has_part>

A predicate for the L</has_part> attribute.

=head2 C<headline>

Headline of the article.

A headline should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_headline>

A predicate for the L</headline> attribute.

=head2 C<in_language>

C<inLanguage>

=for html <p>The language of the content or performance or used in an action. Please
use one of the language codes from the <a
href="http://tools.ietf.org/html/bcp47">IETF BCP 47 standard</a>. See also
<a class="localLink"
href="http://schema.org/availableLanguage">availableLanguage</a>.<p>

A in_language should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Language']>

=item C<Str>

=back

=head2 C<_has_in_language>

A predicate for the L</in_language> attribute.

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

=head2 C<interactivity_type>

C<interactivityType>

The predominant mode of learning supported by the learning resource.
Acceptable values are 'active', 'expositive', or 'mixed'.

A interactivity_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_interactivity_type>

A predicate for the L</interactivity_type> attribute.

=head2 C<is_accessible_for_free>

C<isAccessibleForFree>

A flag to signal that the item, event, or place is accessible for free.

A is_accessible_for_free should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_is_accessible_for_free>

A predicate for the L</is_accessible_for_free> attribute.

=head2 C<is_based_on>

C<isBasedOn>

A resource from which this work is derived or from which it is a
modification or adaption.

A is_based_on should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=item C<Str>

=back

=head2 C<_has_is_based_on>

A predicate for the L</is_based_on> attribute.

=head2 C<is_based_on_url>

C<isBasedOnUrl>

A resource that was used in the creation of this resource. This term can be
repeated for multiple sources. For example,
http://example.com/great-multiplication-intro.html.

A is_based_on_url should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=item C<Str>

=back

=head2 C<_has_is_based_on_url>

A predicate for the L</is_based_on_url> attribute.

=head2 C<is_family_friendly>

C<isFamilyFriendly>

Indicates whether this content is family friendly.

A is_family_friendly should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_is_family_friendly>

A predicate for the L</is_family_friendly> attribute.

=head2 C<is_part_of>

C<isPartOf>

Indicates an item or CreativeWork that this item, or CreativeWork (in some
sense), is part of.

A is_part_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_is_part_of>

A predicate for the L</is_part_of> attribute.

=head2 C<keywords>

Keywords or tags used to describe this content. Multiple entries in a
keywords list are typically delimited by commas.

A keywords should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_keywords>

A predicate for the L</keywords> attribute.

=head2 C<learning_resource_type>

C<learningResourceType>

The predominant type or kind characterizing the learning resource. For
example, 'presentation', 'handout'.

A learning_resource_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_learning_resource_type>

A predicate for the L</learning_resource_type> attribute.

=head2 C<license>

A license document that applies to this content, typically indicated by
URL.

A license should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_license>

A predicate for the L</license> attribute.

=head2 C<location_created>

C<locationCreated>

The location where the CreativeWork was created, which may not be the same
as the location depicted in the CreativeWork.

A location_created should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_location_created>

A predicate for the L</location_created> attribute.

=head2 C<main_entity>

C<mainEntity>

Indicates the primary entity described in some page or other CreativeWork.

A main_entity should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<_has_main_entity>

A predicate for the L</main_entity> attribute.

=head2 C<maintainer>

=for html <p>A maintainer of a <a class="localLink"
href="http://schema.org/Dataset">Dataset</a>, software package (<a
class="localLink"
href="http://schema.org/SoftwareApplication">SoftwareApplication</a>), or
other <a class="localLink" href="http://schema.org/Project">Project</a>. A
maintainer is a <a class="localLink"
href="http://schema.org/Person">Person</a> or <a class="localLink"
href="http://schema.org/Organization">Organization</a> that manages
contributions to, and/or publication of, some (typically complex) artifact.
It is common for distributions of software and data to be based on
"upstream" sources. When <a class="localLink"
href="http://schema.org/maintainer">maintainer</a> is applied to a specific
version of something e.g. a particular version or packaging of a <a
class="localLink" href="http://schema.org/Dataset">Dataset</a>, it is
always possible that the upstream source has a different maintainer. The <a
class="localLink" href="http://schema.org/isBasedOn">isBasedOn</a> property
can be used to indicate such relationships between datasets to make the
different maintenance roles clear. Similarly in the case of software, a
package may have dedicated maintainers working on integration into software
distributions such as Ubuntu, as well as upstream maintainers of the
underlying work.<p>

A maintainer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_maintainer>

A predicate for the L</maintainer> attribute.

=head2 C<material>

A material that something is made from, e.g. leather, wool, cotton, paper.

A material should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=item C<Str>

=back

=head2 C<_has_material>

A predicate for the L</material> attribute.

=head2 C<mentions>

Indicates that the CreativeWork contains a reference to, but is not
necessarily about a concept.

A mentions should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<_has_mentions>

A predicate for the L</mentions> attribute.

=head2 C<offers>

=for html <p>An offer to provide this item&#x2014;for example, an offer to sell a
product, rent the DVD of a movie, perform a service, or give away tickets
to an event. Use <a class="localLink"
href="http://schema.org/businessFunction">businessFunction</a> to indicate
the kind of transaction offered, i.e. sell, lease, etc. This property can
also be used to describe a <a class="localLink"
href="http://schema.org/Demand">Demand</a>. While this property is listed
as expected on a number of common types, it can be used in others. In that
case, using a second type, such as Product or a subtype of Product, can
clarify the nature of the offer.<p>

A offers should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Demand']>

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<_has_offers>

A predicate for the L</offers> attribute.

=head2 C<position>

The position of an item in a series or sequence of items.

A position should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=item C<Str>

=back

=head2 C<_has_position>

A predicate for the L</position> attribute.

=head2 C<producer>

The person or organization who produced the work (e.g. music album, movie,
tv/radio series etc.).

A producer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_producer>

A predicate for the L</producer> attribute.

=head2 C<provider>

The service provider, service operator, or service performer; the goods
producer. Another party (a seller) may offer those services or goods on
behalf of the provider. A provider may also serve as the seller.

A provider should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_provider>

A predicate for the L</provider> attribute.

=head2 C<publication>

A publication event associated with the item.

A publication should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PublicationEvent']>

=back

=head2 C<_has_publication>

A predicate for the L</publication> attribute.

=head2 C<publisher>

The publisher of the creative work.

A publisher should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_publisher>

A predicate for the L</publisher> attribute.

=head2 C<publisher_imprint>

C<publisherImprint>

The publishing division which published the comic.

A publisher_imprint should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_publisher_imprint>

A predicate for the L</publisher_imprint> attribute.

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

=head2 C<recorded_at>

C<recordedAt>

The Event where the CreativeWork was recorded. The CreativeWork may capture
all or part of the event.

A recorded_at should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Event']>

=back

=head2 C<_has_recorded_at>

A predicate for the L</recorded_at> attribute.

=head2 C<released_event>

C<releasedEvent>

The place and time the release was issued, expressed as a PublicationEvent.

A released_event should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PublicationEvent']>

=back

=head2 C<_has_released_event>

A predicate for the L</released_event> attribute.

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

=head2 C<schema_version>

C<schemaVersion>

Indicates (by URL or string) a particular version of a schema used in some
CreativeWork. For example, a document could declare a schemaVersion using
an URL such as http://schema.org/version/2.0/ if precise indication of
schema version was required by some application.

A schema_version should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_schema_version>

A predicate for the L</schema_version> attribute.

=head2 C<sd_date_published>

C<sdDatePublished>

=for html <p>Indicates the date on which the current structured data was generated /
published. Typically used alongside <a class="localLink"
href="http://schema.org/sdPublisher">sdPublisher</a><p>

A sd_date_published should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_sd_date_published>

A predicate for the L</sd_date_published> attribute.

=head2 C<sd_license>

C<sdLicense>

A license document that applies to this structured data, typically
indicated by URL.

A sd_license should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_sd_license>

A predicate for the L</sd_license> attribute.

=head2 C<sd_publisher>

C<sdPublisher>

=for html <p>Indicates the party responsible for generating and publishing the
current structured data markup, typically in cases where the structured
data is derived automatically from existing published content but published
on a different site. For example, student projects and open data
initiatives often re-publish existing content with more explicitly
structured metadata. The <a class="localLink"
href="http://schema.org/sdPublisher">sdPublisher</a> property helps make
such practices more explicit.<p>

A sd_publisher should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_sd_publisher>

A predicate for the L</sd_publisher> attribute.

=head2 C<source_organization>

C<sourceOrganization>

The Organization on whose behalf the creator was working.

A source_organization should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_source_organization>

A predicate for the L</source_organization> attribute.

=head2 C<spatial>

=for html <p>The "spatial" property can be used in cases when more specific
properties (e.g. <a class="localLink"
href="http://schema.org/locationCreated">locationCreated</a>, <a
class="localLink"
href="http://schema.org/spatialCoverage">spatialCoverage</a>, <a
class="localLink"
href="http://schema.org/contentLocation">contentLocation</a>) are not known
to be appropriate.<p>

A spatial should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_spatial>

A predicate for the L</spatial> attribute.

=head2 C<spatial_coverage>

C<spatialCoverage>

The spatialCoverage of a CreativeWork indicates the place(s) which are the
focus of the content. It is a subproperty of contentLocation intended
primarily for more technical and detailed materials. For example with a
Dataset, it indicates areas that the dataset describes: a dataset of New
York weather would have spatialCoverage which was the place: the state of
New York.

A spatial_coverage should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_spatial_coverage>

A predicate for the L</spatial_coverage> attribute.

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

=head2 C<temporal>

=for html <p>The "temporal" property can be used in cases where more specific
properties (e.g. <a class="localLink"
href="http://schema.org/temporalCoverage">temporalCoverage</a>, <a
class="localLink" href="http://schema.org/dateCreated">dateCreated</a>, <a
class="localLink" href="http://schema.org/dateModified">dateModified</a>,
<a class="localLink"
href="http://schema.org/datePublished">datePublished</a>) are not known to
be appropriate.<p>

A temporal should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_temporal>

A predicate for the L</temporal> attribute.

=head2 C<temporal_coverage>

C<temporalCoverage>

=for html <p>The temporalCoverage of a CreativeWork indicates the period that the
content applies to, i.e. that it describes, either as a DateTime or as a
textual string indicating a time period in <a
href="https://en.wikipedia.org/wiki/ISO_8601#Time_intervals">ISO 8601 time
interval format</a>. In the case of a Dataset it will typically indicate
the relevant time period in a precise notation (e.g. for a 2011 census
dataset, the year 2011 would be written "2011/2012"). Other forms of
content e.g. ScholarlyArticle, Book, TVSeries or TVEpisode may indicate
their temporalCoverage in broader terms - textually or via well-known URL.
Written works such as books may sometimes have precise temporal coverage
too, e.g. a work set in 1939 - 1945 can be indicated in ISO 8601 interval
format format via "1939/1945".<br/><br/> Open-ended date ranges can be
written with ".." in place of the end date. For example, "2015-11/.."
indicates a range beginning in November 2015 and with no specified final
date. This is tentative and might be updated in future when ISO 8601 is
officially updated.<p>

A temporal_coverage should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_temporal_coverage>

A predicate for the L</temporal_coverage> attribute.

=head2 C<text>

The textual content of this CreativeWork.

A text should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_text>

A predicate for the L</text> attribute.

=head2 C<thumbnail_url>

C<thumbnailUrl>

A thumbnail image relevant to the Thing.

A thumbnail_url should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_thumbnail_url>

A predicate for the L</thumbnail_url> attribute.

=head2 C<time_required>

C<timeRequired>

Approximate or typical time it takes to work with or through this learning
resource for the typical intended target audience, e.g. 'PT30M', 'PT1H25M'.

A time_required should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<_has_time_required>

A predicate for the L</time_required> attribute.

=head2 C<translation_of_work>

C<translationOfWork>

The work that this work has been translated from. e.g. ç©ç§èµ·æº is a
translationOf âOn the Origin of Speciesâ

A translation_of_work should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=back

=head2 C<_has_translation_of_work>

A predicate for the L</translation_of_work> attribute.

=head2 C<translator>

Organization or person who adapts a creative work to different languages,
regional differences and technical requirements of a target market, or that
translates during some event.

A translator should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_translator>

A predicate for the L</translator> attribute.

=head2 C<typical_age_range>

C<typicalAgeRange>

The typical expected age range, e.g. '7-9', '11-'.

A typical_age_range should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_typical_age_range>

A predicate for the L</typical_age_range> attribute.

=head2 C<usage_info>

C<usageInfo>

=for html <p>The schema.org <a class="localLink"
href="http://schema.org/usageInfo">usageInfo</a> property indicates further
information about a <a class="localLink"
href="http://schema.org/CreativeWork">CreativeWork</a>. This property is
applicable both to works that are freely available and to those that
require payment or other transactions. It can reference additional
information e.g. community expectations on preferred linking and citation
conventions, as well as purchasing details. For something that can be
commercially licensed, usageInfo can provide detailed, resource-specific
information about licensing options.<br/><br/> This property can be used
alongside the license property which indicates license(s) applicable to
some piece of content. The usageInfo property can provide information about
other licensing options, e.g. acquiring commercial usage rights for an
image that is also available under non-commercial creative commons
licenses.<p>

A usage_info should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<Str>

=back

=head2 C<_has_usage_info>

A predicate for the L</usage_info> attribute.

=head2 C<version>

The version of the CreativeWork embodied by a specified resource.

A version should be one of the following types:

=over

=item C<Num>

=item C<Str>

=back

=head2 C<_has_version>

A predicate for the L</version> attribute.

=head2 C<video>

An embedded video object.

A video should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Clip']>

=item C<InstanceOf['SemanticWeb::Schema::VideoObject']>

=back

=head2 C<_has_video>

A predicate for the L</video> attribute.

=head2 C<work_example>

C<workExample>

Example/instance/realization/derivation of the concept of this creative
work. eg. The paperback edition, first edition, or eBook.

A work_example should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=back

=head2 C<_has_work_example>

A predicate for the L</work_example> attribute.

=head2 C<work_translation>

C<workTranslation>

A work that is a translation of the content of this work. e.g. è¥¿éè¨
has an English workTranslation âJourney to the Westâ,a German
workTranslation âMonkeys Pilgerfahrtâ and a Vietnamese translation TÃ¢y
du kÃ½ bÃ¬nh kháº£o.

A work_translation should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=back

=head2 C<_has_work_translation>

A predicate for the L</work_translation> attribute.

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
