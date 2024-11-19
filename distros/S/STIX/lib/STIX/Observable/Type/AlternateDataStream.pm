package STIX::Observable::Type::AlternateDataStream;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
use Types::Standard qw(Str Int InstanceOf);
use namespace::autoclean;

extends 'STIX::Object';

use constant PROPERTIES => (qw(
    name hashes size
));

has name   => (is => 'rw', isa => Str, required => 1);
has hashes => (is => 'rw', isa => InstanceOf ['STIX::Common::Hashes']);
has size   => (is => 'rw', isa => Int);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Type::AlternateDataStream - STIX Cyber-observable Object (SCO) - Alternate Data Streams Extension

=head1 SYNOPSIS

    use STIX::Observable::Type::AlternateDataStream;

    my $alternate_data_stream_ext = STIX::Observable::Type::AlternateDataStream->new();


=head1 DESCRIPTION

Specifies a list of NTFS alternate data streams that exist for the file.


=head2 METHODS

L<STIX::Observable::Type::AlternateDataStream> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Observable::Type::AlternateDataStream->new(%properties)

Create a new instance of L<STIX::Observable::Type::AlternateDataStream>.

=item $alternate_data_stream_ext->name

Specifies the name of the alternate data stream.

=item $alternate_data_stream_ext->hashes

Specifies a dictionary of hashes for the data contained in the alternate data stream.

=item $alternate_data_stream_ext->size

Specifies the size of the alternate data stream, in bytes, as a non-negative integer.

=back


=head2 HELPERS

=over

=item $alternate_data_stream_ext->TO_JSON

Helper for JSON encoders.

=item $alternate_data_stream_ext->to_hash

Return the object HASH.

=item $alternate_data_stream_ext->to_string

Encode the object in JSON.

=item $alternate_data_stream_ext->validate

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
