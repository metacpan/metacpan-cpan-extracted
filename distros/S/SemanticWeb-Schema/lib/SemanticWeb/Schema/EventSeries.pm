use utf8;

package SemanticWeb::Schema::EventSeries;

# ABSTRACT: A series of Event s

use Moo;

extends qw/ SemanticWeb::Schema::Event SemanticWeb::Schema::Series /;


use MooX::JSON_LD 'EventSeries';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EventSeries - A series of Event s

=head1 VERSION

version v7.0.4

=head1 DESCRIPTION

=for html <p>A series of <a class="localLink"
href="http://schema.org/Event">Event</a>s. Included events can relate with
the series using the <a class="localLink"
href="http://schema.org/superEvent">superEvent</a> property.<br/><br/> An
EventSeries is a collection of events that share some unifying
characteristic. For example, "The Olympic Games" is a series, which is
repeated regularly. The "2012 London Olympics" can be presented both as an
<a class="localLink" href="http://schema.org/Event">Event</a> in the series
"Olympic Games", and as an <a class="localLink"
href="http://schema.org/EventSeries">EventSeries</a> that included a number
of sporting competitions as Events.<br/><br/> The nature of the association
between the events in an <a class="localLink"
href="http://schema.org/EventSeries">EventSeries</a> can vary, but typical
examples could include a thematic event series (e.g. topical meetups or
classes), or a series of regular events that share a location, attendee
group and/or organizers.<br/><br/> EventSeries has been defined as a kind
of Event to make it easy for publishers to use it in an Event context
without worrying about which kinds of series are really event-like enough
to call an Event. In general an EventSeries may seem more Event-like when
the period of time is compact and when aspects such as location are fixed,
but it may also sometimes prove useful to describe a longer-term series as
an Event.<p>

=head1 SEE ALSO

L<SemanticWeb::Schema::Series>

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
