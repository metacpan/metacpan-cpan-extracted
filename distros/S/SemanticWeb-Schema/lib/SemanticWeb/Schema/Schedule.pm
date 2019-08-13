use utf8;

package SemanticWeb::Schema::Schedule;

# ABSTRACT: A schedule defines a repeating time period used to describe a regularly occurring <a class="localLink" href="http://schema

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Schedule';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.9.0';


has by_day => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'byDay',
);



has by_month => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'byMonth',
);



has by_month_day => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'byMonthDay',
);



has event_schedule => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'eventSchedule',
);



has except_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'exceptDate',
);



has repeat_count => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'repeatCount',
);



has repeat_frequency => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'repeatFrequency',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Schedule - A schedule defines a repeating time period used to describe a regularly occurring <a class="localLink" href="http://schema

=head1 VERSION

version v3.9.0

=head1 DESCRIPTION

=for html A schedule defines a repeating time period used to describe a regularly
occurring <a class="localLink" href="http://schema.org/Event">Event</a>. At
a minimum a schedule will specify <a class="localLink"
href="http://schema.org/repeatFrequency">repeatFrequency</a> which
describes the interval between occurences of the event. Additional
information can be provided to specify the schedule more precisely. This
includes identifying the day(s) of the week or month when the recurring
event will take place, in addition to its start and end time. Schedules may
also have start and end dates to indicate when they are active, e.g. to
define a limited calendar of events.

=head1 ATTRIBUTES

=head2 C<by_day>

C<byDay>

=for html Defines the day(s) of the week on which a recurring <a class="localLink"
href="http://schema.org/Event">Event</a> takes place

A by_day should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DayOfWeek']>

=back

=head2 C<by_month>

C<byMonth>

=for html Defines the month(s) of the year on which a recurring <a class="localLink"
href="http://schema.org/Event">Event</a> takes place. Specified as an <a
class="localLink" href="http://schema.org/Integer">Integer</a> between
1-12. January is 1.

A by_month should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<by_month_day>

C<byMonthDay>

=for html Defines the day(s) of the month on which a recurring <a class="localLink"
href="http://schema.org/Event">Event</a> takes place. Specified as an <a
class="localLink" href="http://schema.org/Integer">Integer</a> between
1-31.

A by_month_day should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<event_schedule>

C<eventSchedule>

=for html Associates an <a class="localLink" href="http://schema.org/Event">Event</a>
with a <a class="localLink" href="http://schema.org/Schedule">Schedule</a>.
There are circumstances where it is preferable to share a schedule for a
series of repeating events rather than data on the individual events
themselves. For example, a website or application might prefer to publish a
schedule for a weekly gym class rather than provide data on every event. A
schedule could be processed by applications to add forthcoming events to a
calendar. An <a class="localLink" href="http://schema.org/Event">Event</a>
that is associated with a <a class="localLink"
href="http://schema.org/Schedule">Schedule</a> using this property should
not have <a class="localLink"
href="http://schema.org/startDate">startDate</a> or <a class="localLink"
href="http://schema.org/endDate">endDate</a> properties. These are instead
defined within the associated <a class="localLink"
href="http://schema.org/Schedule">Schedule</a>, this avoids any ambiguity
for clients using the data. The propery might have repeated values to
specify different schedules, e.g. for different months or seasons.

A event_schedule should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<except_date>

C<exceptDate>

=for html Defines a <a class="localLink" href="http://schema.org/Date">Date</a> or <a
class="localLink" href="http://schema.org/DateTime">DateTime</a> during
which a scheduled <a class="localLink"
href="http://schema.org/Event">Event</a> will not take place. The property
allows exceptions to a <a class="localLink"
href="http://schema.org/Schedule">Schedule</a> to be specified. If an
exception is specified as a <a class="localLink"
href="http://schema.org/DateTime">DateTime</a> then only the event that
would have started at that specific date and time should be excluded from
the schedule. If an exception is specified as a <a class="localLink"
href="http://schema.org/Date">Date</a> then any event that is scheduled for
that 24 hour period should be excluded from the schedule. This allows a
whole day to be excluded from the schedule without having to itemise every
scheduled event.

A except_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<repeat_count>

C<repeatCount>

=for html Defines the number of times a recurring <a class="localLink"
href="http://schema.org/Event">Event</a> will take place

A repeat_count should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<repeat_frequency>

C<repeatFrequency>

=for html Defines the frequency at which <a class="localLink"
href="http://schema.org/Events">Events</a> will occur according to a
schedule <a class="localLink"
href="http://schema.org/Schedule">Schedule</a>. The intervals between
events should be defined as a <a class="localLink"
href="http://schema.org/Duration">Duration</a> of time.

A repeat_frequency should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

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
