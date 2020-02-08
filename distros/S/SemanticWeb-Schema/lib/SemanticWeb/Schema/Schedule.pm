use utf8;

package SemanticWeb::Schema::Schedule;

# ABSTRACT: A schedule defines a repeating time period used to describe a regularly occurring Event 

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Schedule';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.1';


has by_day => (
    is        => 'rw',
    predicate => '_has_by_day',
    json_ld   => 'byDay',
);



has by_month => (
    is        => 'rw',
    predicate => '_has_by_month',
    json_ld   => 'byMonth',
);



has by_month_day => (
    is        => 'rw',
    predicate => '_has_by_month_day',
    json_ld   => 'byMonthDay',
);



has duration => (
    is        => 'rw',
    predicate => '_has_duration',
    json_ld   => 'duration',
);



has except_date => (
    is        => 'rw',
    predicate => '_has_except_date',
    json_ld   => 'exceptDate',
);



has repeat_count => (
    is        => 'rw',
    predicate => '_has_repeat_count',
    json_ld   => 'repeatCount',
);



has repeat_frequency => (
    is        => 'rw',
    predicate => '_has_repeat_frequency',
    json_ld   => 'repeatFrequency',
);



has schedule_timezone => (
    is        => 'rw',
    predicate => '_has_schedule_timezone',
    json_ld   => 'scheduleTimezone',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Schedule - A schedule defines a repeating time period used to describe a regularly occurring Event 

=head1 VERSION

version v6.0.1

=head1 DESCRIPTION

=for html <p>A schedule defines a repeating time period used to describe a regularly
occurring <a class="localLink" href="http://schema.org/Event">Event</a>. At
a minimum a schedule will specify <a class="localLink"
href="http://schema.org/repeatFrequency">repeatFrequency</a> which
describes the interval between occurences of the event. Additional
information can be provided to specify the schedule more precisely. This
includes identifying the day(s) of the week or month when the recurring
event will take place, in addition to its start and end time. Schedules may
also have start and end dates to indicate when they are active, e.g. to
define a limited calendar of events.<p>

=head1 ATTRIBUTES

=head2 C<by_day>

C<byDay>

=for html <p>Defines the day(s) of the week on which a recurring <a class="localLink"
href="http://schema.org/Event">Event</a> takes place. May be specified
using either <a class="localLink"
href="http://schema.org/DayOfWeek">DayOfWeek</a>, or alternatively <a
class="localLink" href="http://schema.org/Text">Text</a> conforming to
iCal's syntax for byDay recurrence rules<p>

A by_day should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DayOfWeek']>

=item C<Str>

=back

=head2 C<_has_by_day>

A predicate for the L</by_day> attribute.

=head2 C<by_month>

C<byMonth>

=for html <p>Defines the month(s) of the year on which a recurring <a
class="localLink" href="http://schema.org/Event">Event</a> takes place.
Specified as an <a class="localLink"
href="http://schema.org/Integer">Integer</a> between 1-12. January is 1.<p>

A by_month should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_by_month>

A predicate for the L</by_month> attribute.

=head2 C<by_month_day>

C<byMonthDay>

=for html <p>Defines the day(s) of the month on which a recurring <a
class="localLink" href="http://schema.org/Event">Event</a> takes place.
Specified as an <a class="localLink"
href="http://schema.org/Integer">Integer</a> between 1-31.<p>

A by_month_day should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_by_month_day>

A predicate for the L</by_month_day> attribute.

=head2 C<duration>

=for html <p>The duration of the item (movie, audio recording, event, etc.) in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>.<p>

A duration should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<_has_duration>

A predicate for the L</duration> attribute.

=head2 C<except_date>

C<exceptDate>

=for html <p>Defines a <a class="localLink" href="http://schema.org/Date">Date</a> or
<a class="localLink" href="http://schema.org/DateTime">DateTime</a> during
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
scheduled event.<p>

A except_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_except_date>

A predicate for the L</except_date> attribute.

=head2 C<repeat_count>

C<repeatCount>

=for html <p>Defines the number of times a recurring <a class="localLink"
href="http://schema.org/Event">Event</a> will take place<p>

A repeat_count should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_repeat_count>

A predicate for the L</repeat_count> attribute.

=head2 C<repeat_frequency>

C<repeatFrequency>

=for html <p>Defines the frequency at which <a class="localLink"
href="http://schema.org/Events">Events</a> will occur according to a
schedule <a class="localLink"
href="http://schema.org/Schedule">Schedule</a>. The intervals between
events should be defined as a <a class="localLink"
href="http://schema.org/Duration">Duration</a> of time.<p>

A repeat_frequency should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=item C<Str>

=back

=head2 C<_has_repeat_frequency>

A predicate for the L</repeat_frequency> attribute.

=head2 C<schedule_timezone>

C<scheduleTimezone>

=for html <p>Indicates the timezone for which the time(s) indicated in the <a
class="localLink" href="http://schema.org/Schedule">Schedule</a> are given.
The value provided should be among those listed in the IANA Time Zone
Database.<p>

A schedule_timezone should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_schedule_timezone>

A predicate for the L</schedule_timezone> attribute.

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
