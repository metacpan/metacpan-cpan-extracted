package Net::RDAP::Event;
use DateTime::Format::ISO8601;
use Net::RDAP::Link;
use base qw(Net::RDAP::Base);
use strict;

=pod

=head1 NAME

L<Net::RDAP::Event> - object representing an RDAP event.

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

sub date { DateTime::Format::ISO8601->parse_datetime($_[0]->{'eventDate'}) }

=pod

=head1 COPYRIGHT

Copyright 2018 CentralNic Ltd. All rights reserved.

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1;
