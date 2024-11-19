package STIX::Observable::File;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str HashRef Int InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/file.json';

use constant PROPERTIES => (
    qw(type id),
    qw(spec_version object_marking_refs granular_markings defanged extensions),
    qw(hashes size name name_enc magic_number_hex mime_type ctime mtime atime parent_directory_ref contains_refs content_ref),
);

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'file';

has hashes   => (is => 'rw', isa => InstanceOf ['STIX::Common::Hashes']);
has size     => (is => 'rw', isa => Int);
has name     => (is => 'rw', isa => Str);
has name_enc => (is => 'rw', isa => Str);

has magic_number_hex => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Hex'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Hex->new($_[0]) }
);

has mime_type => (is => 'rw', isa => Str);

has ctime => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has mtime => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has atime => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has parent_directory_ref => (is => 'rw', isa => InstanceOf ['STIX::Observable::Directory', 'STIX::Common::Identifier']);
has contains_refs =>
    (is => 'rw', isa => ArrayLike [InstanceOf ['STIX::Observable']], default => sub { STIX::Common::List->new });
has content_ref => (is => 'rw', isa => InstanceOf ['STIX::Observable::Artifact']);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::File - STIX Cyber-observable Object (SCO) - File

=head1 SYNOPSIS

    use STIX::Observable::File;

    my $file = STIX::Observable::File->new();


=head1 DESCRIPTION

The File Object represents the properties of a file.


=head2 METHODS

L<STIX::Observable::File> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::File->new(%properties)

Create a new instance of L<STIX::Observable::File>.

=item $file->atime

Specifies the date/time the file was last accessed.

=item $file->contains_refs

Specifies a list of references to other Observable Objects contained within
the file.

=item $file->content_ref

Specifies the content of the file, represented as an Artifact Object.

=item $file->ctime

Specifies the date/time the file was created.

=item $file->extensions

The File Object defines the following extensions. In addition to these,
producers MAY create their own. Extensions: ntfs-ext, raster-image-ext,
pdf-ext, archive-ext, windows-pebinary-ext

=item $file->hashes

Specifies a dictionary of hashes for the file.

=item $file->id

=item $file->magic_number_hex

Specifies the hexadecimal constant ('magic number') associated with a
specific file format that corresponds to the file, if applicable.

=item $file->mime_type

Specifies the MIME type name specified for the file, e.g.,
'application/msword'.

=item $file->mtime

Specifies the date/time the file was last written to/modified.

=item $file->name

Specifies the name of the file.

=item $file->name_enc

Specifies the observed encoding for the name of the file.

=item $file->parent_directory_ref

Specifies the parent directory of the file, as a reference to a Directory
Object.

=item $file->size

Specifies the size of the file, in bytes, as a non-negative integer.

=item $file->type

The value of this property MUST be C<file>.

=back


=head2 HELPERS

=over

=item $file->TO_JSON

Encode the object in JSON.

=item $file->to_hash

Return the object HASH.

=item $file->to_string

Encode the object in JSON.

=item $file->validate

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
