package STIX::Observable::Extension::NTFS;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant PROPERTIES => (qw[
    sid
    alternate_data_streams
]);

use constant EXTENSION_TYPE => 'ntfs-ext';

has sid => (is => 'rw', isa => Str);

has alternate_data_streams => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Observable::Type::AlternateDataStream']],
    default => sub { STIX::Common::List->new }
);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Extension::NTFS - STIX Cyber-observable Object (SCO) - NTFS File Extension

=head1 SYNOPSIS

    use STIX::Observable::Extension::NTFS;

    my $ntfs_ext = STIX::Observable::Extension::NTFS->new();


=head1 DESCRIPTION

The NTFS file extension specifies a default extension for capturing properties
specific to the storage of the file on the NTFS file system.

=head2 METHODS

L<STIX::Observable::Extension::NTFS> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Observable::Extension::NTFS->new(%properties)

Create a new instance of L<STIX::Observable::Extension::NTFS>.

=item $ntfs_ext->sid

Specifies the security ID (SID) value assigned to the file.

=item $ntfs_ext->alternate_data_streams

Specifies a list of NTFS alternate data streams that exist for the file
(see L<STIX::Observable::Type::AlternateDataStream>).

=back


=head2 HELPERS

=over

=item $ntfs_ext->TO_JSON

Helper for JSON encoders.

=item $ntfs_ext->to_hash

Return the object HASH.

=item $ntfs_ext->to_string

Encode the object in JSON.

=item $ntfs_ext->validate

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
