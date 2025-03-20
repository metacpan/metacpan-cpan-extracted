package Net::RDAP::Event;
use DateTime::Tiny;
use base qw(Net::RDAP::Base);
use strict;
use warnings;

=pod

=head1 NAME

L<Net::RDAP::Event> - a module representing an RDAP event.

=head1 DESCRIPTION

RDAP objects and records may have zero or more "events"
associated with them. The C<events()> method of various
C<Net::RDAP::Object::> modules may return an array of
L<Net::RDAP::Event> objects.

=head1 METHODS

=head2 Event Action

    $action = $event->action;

Returns a string containing the event action. The list
of possible values is defined by an IANA registry, see:

=over

=item * L<https://www.iana.org/assignments/rdap-json-values/rdap-json-values.xhtml>

=back

=cut

sub action { $_[0]->{'eventAction'} }

=pod

=head2 Event Actor

    $actor = $event->actor;

Returns a string containing the handle of the entity
responsible for causing the event.

=cut

sub actor { $_[0]->{'eventActor'} }

=pod

=head2 Event Date

    $date = $event->date;

Returns a L<DateTime::Tiny> object corresponding to the date and time of the
event.

Prior to Net::RDAP v0.35, this method returned a L<DateTime>, but this was
switched to L<DateTime::Tiny> for performance reasons. If you need a
L<DateTime>, use C<$event-E<gt>date-E<gt>DateTime>.

=cut

sub date { DateTime::Tiny->from_string(substr(shift->{eventDate}, 0, 19)) }

=pod

=head2 Event Time Zone

    $tz = $event->date_tz;

Since L<DateTime::Tiny> does not support time zones, this method will return the
time zone part of the C<eventDate> property. For a well-formed C<eventDate>
value, this will either be C<Z> (indicating UTC, or an offset of the form
C<+/-HH:MM>.

=cut

sub date_tz {
    my $str = substr(shift->{eventDate}, 19);
    $str =~ s/^\.\d+//g;
    return $str;
}

=pod

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024-2025 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
