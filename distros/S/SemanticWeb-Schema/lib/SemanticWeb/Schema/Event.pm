use utf8;

package SemanticWeb::Schema::Event;

# ABSTRACT: An event happening at a certain time and location

use Moo;

extends qw/ SemanticWeb::Schema::Thing /;


use MooX::JSON_LD 'Event';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has about => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'about',
);



has actor => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'actor',
);



has aggregate_rating => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'aggregateRating',
);



has attendee => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'attendee',
);



has attendees => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'attendees',
);



has audience => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'audience',
);



has composer => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'composer',
);



has contributor => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'contributor',
);



has director => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'director',
);



has door_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'doorTime',
);



has duration => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'duration',
);



has end_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'endDate',
);



has event_status => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'eventStatus',
);



has funder => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'funder',
);



has in_language => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'inLanguage',
);



has is_accessible_for_free => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'isAccessibleForFree',
);



has location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'location',
);



has maximum_attendee_capacity => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'maximumAttendeeCapacity',
);



has offers => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'offers',
);



has organizer => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'organizer',
);



has performer => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'performer',
);



has performers => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'performers',
);



has previous_start_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'previousStartDate',
);



has recorded_in => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'recordedIn',
);



has remaining_attendee_capacity => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'remainingAttendeeCapacity',
);



has review => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'review',
);



has sponsor => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'sponsor',
);



has start_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'startDate',
);



has sub_event => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'subEvent',
);



has sub_events => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'subEvents',
);



has super_event => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'superEvent',
);



has translator => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'translator',
);



has typical_age_range => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'typicalAgeRange',
);



has work_featured => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'workFeatured',
);



has work_performed => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'workPerformed',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Event - An event happening at a certain time and location

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html An event happening at a certain time and location, such as a concert,
lecture, or festival. Ticketing information may be added via the <a
class="localLink" href="http://schema.org/offers">offers</a> property.
Repeated events may be structured as separate Event objects.

=head1 ATTRIBUTES

=head2 C<about>

The subject matter of the content.

A about should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<actor>

An actor, e.g. in tv, radio, movie, video games etc., or in an event.
Actors can be associated with individual items or with a series, episode,
clip.

A actor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<aggregate_rating>

C<aggregateRating>

The overall rating, based on a collection of reviews or ratings, of the
item.

A aggregate_rating should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AggregateRating']>

=back

=head2 C<attendee>

A person or organization attending the event.

A attendee should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<attendees>

A person attending the event.

A attendees should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<audience>

An intended audience, i.e. a group for whom something was created.

A audience should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Audience']>

=back

=head2 C<composer>

The person or organization who wrote a composition, or who is the composer
of a work performed at some event.

A composer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<contributor>

A secondary contributor to the CreativeWork or Event.

A contributor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<director>

A director of e.g. tv, radio, movie, video gaming etc. content, or of an
event. Directors can be associated with individual items or with a series,
episode, clip.

A director should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<door_time>

C<doorTime>

The time admission will commence.

A door_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<duration>

=for html The duration of the item (movie, audio recording, event, etc.) in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>.

A duration should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<end_date>

C<endDate>

=for html The end date and time of the item (in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>).

A end_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<event_status>

C<eventStatus>

An eventStatus of an event represents its status; particularly useful when
an event is cancelled or rescheduled.

A event_status should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::EventStatusType']>

=back

=head2 C<funder>

A person or organization that supports (sponsors) something through some
kind of financial contribution.

A funder should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<in_language>

C<inLanguage>

=for html The language of the content or performance or used in an action. Please use
one of the language codes from the <a
href="http://tools.ietf.org/html/bcp47">IETF BCP 47 standard</a>. See also
<a class="localLink"
href="http://schema.org/availableLanguage">availableLanguage</a>.

A in_language should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Language']>

=item C<Str>

=back

=head2 C<is_accessible_for_free>

C<isAccessibleForFree>

A flag to signal that the item, event, or place is accessible for free.

A is_accessible_for_free should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<location>

The location of for example where the event is happening, an organization
is located, or where an action takes place.

A location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<InstanceOf['SemanticWeb::Schema::PostalAddress']>

=item C<Str>

=back

=head2 C<maximum_attendee_capacity>

C<maximumAttendeeCapacity>

The total number of individuals that may attend an event or venue.

A maximum_attendee_capacity should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<offers>

An offer to provide this item&#x2014;for example, an offer to sell a
product, rent the DVD of a movie, perform a service, or give away tickets
to an event.

A offers should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<organizer>

An organizer of an Event.

A organizer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<performer>

A performer at the event&#x2014;for example, a presenter, musician, musical
group or actor.

A performer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<performers>

The main performer or performers of the event&#x2014;for example, a
presenter, musician, or actor.

A performers should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<previous_start_date>

C<previousStartDate>

Used in conjunction with eventStatus for rescheduled or cancelled events.
This property contains the previously scheduled start date. For rescheduled
events, the startDate property should be used for the newly scheduled start
date. In the (rare) case of an event that has been postponed and
rescheduled multiple times, this field may be repeated.

A previous_start_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<recorded_in>

C<recordedIn>

The CreativeWork that captured all or part of this Event.

A recorded_in should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=back

=head2 C<remaining_attendee_capacity>

C<remainingAttendeeCapacity>

The number of attendee places for an event that remain unallocated.

A remaining_attendee_capacity should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<review>

A review of the item.

A review should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Review']>

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

=head2 C<start_date>

C<startDate>

=for html The start date and time of the item (in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>).

A start_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<sub_event>

C<subEvent>

An Event that is part of this event. For example, a conference event
includes many presentations, each of which is a subEvent of the conference.

A sub_event should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Event']>

=back

=head2 C<sub_events>

C<subEvents>

Events that are a part of this event. For example, a conference event
includes many presentations, each subEvents of the conference.

A sub_events should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Event']>

=back

=head2 C<super_event>

C<superEvent>

An event that this event is a part of. For example, a collection of
individual music performances might each have a music festival as their
superEvent.

A super_event should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Event']>

=back

=head2 C<translator>

Organization or person who adapts a creative work to different languages,
regional differences and technical requirements of a target market, or that
translates during some event.

A translator should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<typical_age_range>

C<typicalAgeRange>

The typical expected age range, e.g. '7-9', '11-'.

A typical_age_range should be one of the following types:

=over

=item C<Str>

=back

=head2 C<work_featured>

C<workFeatured>

A work featured in some event, e.g. exhibited in an ExhibitionEvent.
Specific subproperties are available for workPerformed (e.g. a play), or a
workPresented (a Movie at a ScreeningEvent).

A work_featured should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=back

=head2 C<work_performed>

C<workPerformed>

A work performed in some event, for example a play performed in a
TheaterEvent.

A work_performed should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

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
