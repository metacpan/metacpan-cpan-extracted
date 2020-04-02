use utf8;

package SemanticWeb::Schema::Message;

# ABSTRACT: A single message from a sender to one or more organizations or people.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Message';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.2';


has bcc_recipient => (
    is        => 'rw',
    predicate => '_has_bcc_recipient',
    json_ld   => 'bccRecipient',
);



has cc_recipient => (
    is        => 'rw',
    predicate => '_has_cc_recipient',
    json_ld   => 'ccRecipient',
);



has date_read => (
    is        => 'rw',
    predicate => '_has_date_read',
    json_ld   => 'dateRead',
);



has date_received => (
    is        => 'rw',
    predicate => '_has_date_received',
    json_ld   => 'dateReceived',
);



has date_sent => (
    is        => 'rw',
    predicate => '_has_date_sent',
    json_ld   => 'dateSent',
);



has message_attachment => (
    is        => 'rw',
    predicate => '_has_message_attachment',
    json_ld   => 'messageAttachment',
);



has recipient => (
    is        => 'rw',
    predicate => '_has_recipient',
    json_ld   => 'recipient',
);



has sender => (
    is        => 'rw',
    predicate => '_has_sender',
    json_ld   => 'sender',
);



has to_recipient => (
    is        => 'rw',
    predicate => '_has_to_recipient',
    json_ld   => 'toRecipient',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Message - A single message from a sender to one or more organizations or people.

=head1 VERSION

version v7.0.2

=head1 DESCRIPTION

A single message from a sender to one or more organizations or people.

=head1 ATTRIBUTES

=head2 C<bcc_recipient>

C<bccRecipient>

A sub property of recipient. The recipient blind copied on a message.

A bcc_recipient should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_bcc_recipient>

A predicate for the L</bcc_recipient> attribute.

=head2 C<cc_recipient>

C<ccRecipient>

A sub property of recipient. The recipient copied on a message.

A cc_recipient should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_cc_recipient>

A predicate for the L</cc_recipient> attribute.

=head2 C<date_read>

C<dateRead>

The date/time at which the message has been read by the recipient if a
single recipient exists.

A date_read should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_date_read>

A predicate for the L</date_read> attribute.

=head2 C<date_received>

C<dateReceived>

The date/time the message was received if a single recipient exists.

A date_received should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_date_received>

A predicate for the L</date_received> attribute.

=head2 C<date_sent>

C<dateSent>

The date/time at which the message was sent.

A date_sent should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_date_sent>

A predicate for the L</date_sent> attribute.

=head2 C<message_attachment>

C<messageAttachment>

A CreativeWork attached to the message.

A message_attachment should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=back

=head2 C<_has_message_attachment>

A predicate for the L</message_attachment> attribute.

=head2 C<recipient>

A sub property of participant. The participant who is at the receiving end
of the action.

A recipient should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Audience']>

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_recipient>

A predicate for the L</recipient> attribute.

=head2 C<sender>

A sub property of participant. The participant who is at the sending end of
the action.

A sender should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Audience']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_sender>

A predicate for the L</sender> attribute.

=head2 C<to_recipient>

C<toRecipient>

A sub property of recipient. The recipient who was directly sent the
message.

A to_recipient should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Audience']>

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_to_recipient>

A predicate for the L</to_recipient> attribute.

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
