package STIX::Observable::Type::EmailMIMEPart;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
use Types::Standard qw(Str InstanceOf);
use namespace::autoclean;

extends 'STIX::Object';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/email-message.json#/definitions/mime-part-type';

use constant PROPERTIES => (qw(
    body body_raw_ref content_type content_disposition
));

has body => (is => 'rw', isa => Str);

has body_raw_ref => (
    is  => 'rw',
    isa => InstanceOf ['STIX::Observable::Artifact', 'STIX::Observable::File', 'STIX::Common::Identifier']
);

has content_type        => (is => 'rw', isa => Str);
has content_disposition => (is => 'rw', isa => Str);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Type::EmailMIMEPart - STIX Cyber-observable Object (SCO) - Email MIME Component Type

=head1 SYNOPSIS

    use STIX::Observable::Type::EmailMIMEPart;

    my $mime_part_type = STIX::Observable::Type::EmailMIMEPart->new();


=head1 DESCRIPTION

Specifies a component of a multi-part email body.

L<https://docs.oasis-open.org/cti/stix/v2.1/os/stix-v2.1-os.html#_qpo5x7d8mefq>


=head2 METHODS

L<STIX::Observable::Type::EmailMIMEPart> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Observable::Type::EmailMIMEPart->new(%properties)

Create a new instance of L<STIX::Observable::Type::EmailMIMEPart>.

=item $mime_part_type->body

Specifies the contents of the MIME part if the content_type is not provided
OR starts with text/

=item $mime_part_type->body_raw_ref

Specifies the contents of non-textual MIME parts, that is those whose
content_type does not start with text/, as a reference to an L<STIX::Observable::Artifact>
Object or L<STIX::Observable::File> Object.

=item $mime_part_type->content_disposition

Specifies the value of the 'Content-Disposition' header field of the MIME
part.

=item $mime_part_type->content_type

Specifies the value of the 'Content-Type' header field of the MIME part.

=back


=head2 HELPERS

=over

=item $mime_part_type->TO_JSON

Helper for JSON encoders.

=item $mime_part_type->to_hash

Return the object HASH.

=item $mime_part_type->to_string

Encode the object in JSON.

=item $mime_part_type->validate

Validate the object using JSON Schema (see L<STIX::Schema>).

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
