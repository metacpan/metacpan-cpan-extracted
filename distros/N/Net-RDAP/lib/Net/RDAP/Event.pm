package Net::RDAP::Event;
use DateTime::Format::ISO8601;
use Net::RDAP::Link;
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

Returns a L<DateTime> object corresponding to the date and time of the
event.

=cut

sub date {
    #
    # DateTime::Format::ISO8601 doesn't seem to like strings with "time-secfrac" components, so we strip them out
    #
    my $str = shift->{'eventDate'};
    $str =~ s/(T\d{2}:\d{2}:\d{2})\.\d{1,3}(\+)/$1$2/;

    my $date;
    eval {
        $date = DateTime::Format::ISO8601->parse_datetime($str || '1970-01-01T00:00:00.0Z');
    };
    if ($@) {
        return DateTime::Format::ISO8601->parse_datetime('1970-01-01T00:00:00.0Z');

    } else {
        return $date;

    }
}

=pod

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
