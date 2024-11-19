package STIX::Observable::Extension::Archive;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant PROPERTIES => (qw[
    contains_refs
    comment
]);

use constant EXTENSION_TYPE => 'archive-ext';

has contains_refs => (
    is       => 'rw',
    required => 1,
    isa => ArrayLike [InstanceOf ['STIX::Observable::Directory', 'STIX::Observable::File', 'STIX::Common::Identifier']],
    default => sub { STIX::Common::List->new }
);
has comment => (is => 'rw', isa => Str);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Extension::Archive - STIX Cyber-observable Object (SCO) - Archive File Extension

=head1 SYNOPSIS

    use STIX::Observable::Extension::Archive;

    my $archive_ext = STIX::Observable::Extension::Archive->new();


=head1 DESCRIPTION

The Archive File extension specifies a default extension for capturing properties
specific to archive files.

=head2 METHODS

L<STIX::Observable::Extension::Archive> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Observable::Extension::Archive->new(%properties)

Create a new instance of L<STIX::Observable::Extension::Archive>.

=item $archive_ext->contains_refs

Specifies the files contained in the archive, as a reference to one or more other
File Objects. The objects referenced in this list MUST be of type file-object.

=item $archive_ext->comment

Specifies a comment included as part of the archive file.

=back


=head2 HELPERS

=over

=item $archive_ext->TO_JSON

Helper for JSON encoders.

=item $archive_ext->to_hash

Return the object HASH.

=item $archive_ext->to_string

Encode the object in JSON.

=item $archive_ext->validate

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
