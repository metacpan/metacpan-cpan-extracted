package STIX::Observable::Extension::WindowsPEBinary;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::Hex;
use STIX::Common::OpenVocabulary;
use Types::Standard qw(Str Int InstanceOf Enum);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant PROPERTIES => (qw[
    pe_type imphash machine_hex number_of_sections time_date_stamp pointer_to_symbol_table_hex
    number_of_symbols size_of_optional_header characteristics_hex file_header_hashes
    optional_header sections
]);

use constant EXTENSION_TYPE => 'windows-pebinary-ext';

has pe_type => (is => 'rw', required => 1, isa => Enum [STIX::Common::OpenVocabulary->WINDOWS_PEBINARY_TYPE]);

has imphash => (is => 'rw', isa => Str);

has machine_hex => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Hex'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Hex->new($_[0]) }
);

has number_of_sections => (is => 'rw', isa => Int);

has time_date_stamp => (is => 'rw', isa => InstanceOf ['STIX::Common::Timestamp']);

has pointer_to_symbol_table_hex => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Hex'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Hex->new($_[0]) }
);

has number_of_symbols => (is => 'rw', isa => Int);

has size_of_optional_header => (is => 'rw', isa => Int);

has characteristics_hex => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Hex'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Hex->new($_[0]) }
);

has file_header_hashes => (is => 'rw', isa => InstanceOf ['STIX::Common::Hashes']);

has optional_header => (is => 'rw', isa => InstanceOf ['STIX::Observable::Type::WindowsPEOptionalHeader']);

has sections => (is => 'rw', isa => InstanceOf ['STIX::Observable::Type::WindowsPESection']);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Extension::WindowsPEBinary - STIX Cyber-observable Object (SCO) - Raster Image File Extension

=head1 SYNOPSIS

    use STIX::Observable::Extension::WindowsPEBinary;

    my $windows_pe_binary_ext = STIX::Observable::Extension::WindowsPEBinary->new();


=head1 DESCRIPTION

The Windows PE Binary File extension specifies a default extension for capturing
properties specific to Windows portable executable (PE) files.

=head2 METHODS

L<STIX::Observable::Extension::WindowsPEBinary> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Observable::Extension::WindowsPEBinary->new(%properties)

Create a new instance of L<STIX::Observable::Extension::WindowsPEBinary>.

=item $windows_pe_binary_ext->pe_type

Specifies the type of the PE binary
(see C<WINDOWS_PEBINARY_TYPE> in L<STIX::Common::OpenVocabulary>). 

=item $windows_pe_binary_ext->imphash

Specifies the special import hash, or 'imphash', calculated for the PE Binary
based on its imported libraries and functions.

=item $windows_pe_binary_ext->machine_hex

Specifies the type of target machine.

=item $windows_pe_binary_ext->number_of_sections

Specifies the number of sections in the PE binary, as a non-negative integer.

=item $windows_pe_binary_ext->time_date_stamp

Specifies the time when the PE binary was created.  The timestamp value MUST BE
precise to the second.

=item $windows_pe_binary_ext->pointer_to_symbol_table_hex

Specifies the file offset of the COFF symbol table.

=item $windows_pe_binary_ext->number_of_symbols

Specifies the number of entries in the symbol table of the PE binary, as a
non-negative integer.

=item $windows_pe_binary_ext->size_of_optional_header

Specifies the size of the optional header of the PE binary.

=item $windows_pe_binary_ext->characteristics_hex

Specifies the flags that indicate the file’s characteristics.

=item $windows_pe_binary_ext->file_header_hashes

Specifies any hashes that were computed for the file header
(see L<STIX::Common::Hashes>).

=item $windows_pe_binary_ext->optional_header

Specifies the PE optional header of the PE binary
(see L<STIX::Observable::Type::WindowsPEOptionalHeader>).

=item $windows_pe_binary_ext->sections

Specifies metadata about the sections in the PE file
(see L<STIX::Observable::Type::WindowsPESection>).

=back


=head2 HELPERS

=over

=item $windows_pe_binary_ext->TO_JSON

Helper for JSON encoders.

=item $windows_pe_binary_ext->to_hash

Return the object HASH.

=item $windows_pe_binary_ext->to_string

Encode the object in JSON.

=item $windows_pe_binary_ext->validate

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
