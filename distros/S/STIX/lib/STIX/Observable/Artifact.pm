package STIX::Observable::Artifact;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::Binary;
use STIX::Common::Enum;
use Types::Standard qw(Str InstanceOf Enum);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/artifact.json';

use constant PROPERTIES => (
    qw(type id),
    qw(spec_version object_marking_refs granular_markings defanged extensions),
    qw(mime_type payload_bin url hashes encryption_algorithm decryption_key),
);

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'artifact';

has mime_type => (is => 'rw', isa => Str);

has payload_bin => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Binary'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Binary->new($_[0]) }
);

has url                  => (is => 'rw', isa => Str);
has hashes               => (is => 'rw', isa => InstanceOf ['STIX::Common::Hashes']);
has encryption_algorithm => (is => 'rw', isa => Enum [STIX::Common::Enum->ENCRYPTION_ALGORITHM()]);
has decryption_key       => (is => 'rw', isa => Str);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Artifact - STIX Cyber-observable Object (SCO) - Artifact

=head1 SYNOPSIS

    use STIX::Observable::Artifact;

    my $artifact = STIX::Observable::Artifact->new();


=head1 DESCRIPTION

The Artifact Object permits capturing an array of bytes (8-bits), as a
base64-encoded string string, or linking to a file-like payload.


=head2 METHODS

L<STIX::Observable::Artifact> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::Artifact->new(%properties)

Create a new instance of L<STIX::Observable::Artifact>.

=item $artifact->decryption_key

Specifies the decryption key for the encrypted binary data (either via
payload_bin or url).

=item $artifact->encryption_algorithm

If the artifact is encrypted, specifies the type of encryption algorithm
the binary data  (either via payload_bin or url) is encoded in.

=item $artifact->hashes

Specifies a dictionary of hashes for the contents of the url or the
payload_bin.  This MUST be provided when the url property is present
(see L<STIX::Common::Hashes>).

=item $artifact->id

=item $artifact->mime_type

The value of this property MUST be a valid MIME type as specified in the
IANA Media Types registry.

=item $artifact->payload_bin

Specifies the binary data contained in the artifact as a base64-encoded
string.

=item $artifact->type

The value of this property MUST be C<artifact>.

=item $artifact->url

The value of this property MUST be a valid URL that resolves to the
unencoded content.

=back


=head2 HELPERS

=over

=item $artifact->TO_JSON

Encode the object in JSON.

=item $artifact->to_hash

Return the object HASH.

=item $artifact->to_string

Encode the object in JSON.

=item $artifact->validate

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

