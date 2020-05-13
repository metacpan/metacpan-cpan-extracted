use utf8;

package SemanticWeb::Schema::RsvpAction;

# ABSTRACT: The act of notifying an event organizer as to whether you expect to attend the event.

use Moo;

extends qw/ SemanticWeb::Schema::InformAction /;


use MooX::JSON_LD 'RsvpAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has additional_number_of_guests => (
    is        => 'rw',
    predicate => '_has_additional_number_of_guests',
    json_ld   => 'additionalNumberOfGuests',
);



has comment => (
    is        => 'rw',
    predicate => '_has_comment',
    json_ld   => 'comment',
);



has rsvp_response => (
    is        => 'rw',
    predicate => '_has_rsvp_response',
    json_ld   => 'rsvpResponse',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::RsvpAction - The act of notifying an event organizer as to whether you expect to attend the event.

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

The act of notifying an event organizer as to whether you expect to attend
the event.

=head1 ATTRIBUTES

=head2 C<additional_number_of_guests>

C<additionalNumberOfGuests>

If responding yes, the number of guests who will attend in addition to the
invitee.

A additional_number_of_guests should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_additional_number_of_guests>

A predicate for the L</additional_number_of_guests> attribute.

=head2 C<comment>

Comments, typically from users.

A comment should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Comment']>

=back

=head2 C<_has_comment>

A predicate for the L</comment> attribute.

=head2 C<rsvp_response>

C<rsvpResponse>

The response (yes, no, maybe) to the RSVP.

A rsvp_response should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::RsvpResponseType']>

=back

=head2 C<_has_rsvp_response>

A predicate for the L</rsvp_response> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::InformAction>

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
