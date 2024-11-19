package STIX::Observable::EmailMessage;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::Timestamp;
use Types::Standard qw(Bool Str HashRef InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/email-message.json';

use constant PROPERTIES => (
    qw(type id),
    qw(spec_version object_marking_refs granular_markings defanged extensions),
    qw(is_multipart date content_type from_ref sender_ref to_refs cc_refs bcc_refs subject received_lines additional_header_fields body body_multipart raw_email_ref)
);

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'email-message';

has is_multipart => (is => 'rw', required => 1, isa => Bool);

has date => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has content_type => (is => 'rw', isa => Str);
has from_ref     => (is => 'rw', isa => InstanceOf ['STIX::Obserbable::EmailAddr', 'STIX::Common::Identifier']);
has sender_ref   => (is => 'rw', isa => InstanceOf ['STIX::Obserbable::EmailAddr', 'STIX::Common::Identifier']);

has to_refs => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Obserbable::EmailAddr', 'STIX::Common::Identifier']],
    default => sub { STIX::Common::List->new }
);

has cc_refs => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Obserbable::EmailAddr', 'STIX::Common::Identifier']],
    default => sub { STIX::Common::List->new }
);

has bcc_refs => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Obserbable::EmailAddr', 'STIX::Common::Identifier']],
    default => sub { STIX::Common::List->new }
);

has subject                  => (is => 'rw', isa => Str);
has received_lines           => (is => 'rw', isa => ArrayLike [Str]);
has additional_header_fields => (is => 'rw', isa => HashRef);
has body                     => (is => 'rw', isa => Str);

has body_multipart => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Observable::Type::EmailMIMEPart']],
    default => sub { STIX::Common::List->new }
);

has raw_email_ref => (is => 'rw', isa => InstanceOf ['STIX::Observable::Artifact']);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::EmailMessage - STIX Cyber-observable Object (SCO) - Email Message

=head1 SYNOPSIS

    use STIX::Observable::EmailMessage;

    my $email_message = STIX::Observable::EmailMessage->new();


=head1 DESCRIPTION

The Email Message Object represents an instance of an email message.


=head2 METHODS

L<STIX::Observable::EmailMessage> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::EmailMessage->new(%properties)

Create a new instance of L<STIX::Observable::EmailMessage>.

=item $email_message->additional_header_fields

Specifies any other header fields found in the email message, as a
dictionary.

=item $email_message->bcc_refs

Specifies the mailboxes that are 'BCC:' recipients of the email message.

=item $email_message->cc_refs

Specifies the mailboxes that are 'CC:' recipients of the email message.

=item $email_message->content_type

Specifies the value of the 'Content-Type' header of the email message.

=item $email_message->date

Specifies the date/time that the email message was sent.

=item $email_message->from_ref

Specifies the value of the 'From:' header of the email message.

=item $email_message->id

=item $email_message->message_id

Specifies the Message-ID field of the email message.

=item $email_message->raw_email_ref

Specifies the raw binary contents of the email message, including both the
headers and body, as a reference to an Artifact Object.

=item $email_message->received_lines

Specifies one or more Received header fields that may be included in the
email headers.

=item $email_message->sender_ref

Specifies the value of the 'From' field of the email message.

=item $email_message->subject

Specifies the subject of the email message.

=item $email_message->to_refs

Specifies the mailboxes that are 'To:' recipients of the email message.

=item $email_message->type

The value of this property MUST be C<email-message>.

=back


=head2 HELPERS

=over

=item $email_message->TO_JSON

Encode the object in JSON.

=item $email_message->to_hash

Return the object HASH.

=item $email_message->to_string

Encode the object in JSON.

=item $email_message->validate

Validate the object using JSON Schema
(see L<STIX::Schema>).

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-STIX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-STIX>

    git clone https://github.com/giterlizzi/perl-STIX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
