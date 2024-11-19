package STIX::Observable::Directory;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/directory.json';

use constant PROPERTIES => (
    qw(type id),
    qw(spec_version object_marking_refs granular_markings defanged extensions),
    qw(path path_enc ctime mtime atime contains_refs),
);

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'directory';

has path => (is => 'rw', required => 1, isa => Str);

has path_enc => (is => 'rw', isa => Str);

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

has contains_refs => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Observable::Directory', 'STIX::Observable::File']],
    default => sub { STIX::Common::List->new }
);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Directory - STIX Cyber-observable Object (SCO) - Directory

=head1 SYNOPSIS

    use STIX::Observable::Directory;

    my $directory = STIX::Observable::Directory->new();


=head1 DESCRIPTION

The Directory Object represents the properties common to a file system
directory.


=head2 METHODS

L<STIX::Observable::Directory> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::Directory->new(%properties)

Create a new instance of L<STIX::Observable::Directory>.

=item $directory->atime

Specifies the date/time the directory was last accessed.

=item $directory->contains_refs

Specifies a list of references to other File and/or Directory Objects
contained within the directory.

=item $directory->ctime

Specifies the date/time the directory was created.

=item $directory->id

=item $directory->mtime

Specifies the date/time the directory was last written to/modified.

=item $directory->path

Specifies the path, as originally observed, to the directory on the file
system.

=item $directory->path_enc

Specifies the observed encoding for the path.

=item $directory->type

The value of this property MUST be C<directory>.

=back


=head2 HELPERS

=over

=item $directory->TO_JSON

Encode the object in JSON.

=item $directory->to_hash

Return the object HASH.

=item $directory->to_string

Encode the object in JSON.

=item $directory->validate

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
