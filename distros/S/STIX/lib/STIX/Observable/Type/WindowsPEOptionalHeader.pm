package STIX::Observable::Type::WindowsPEOptionalHeader;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::Hex;

use Moo;
use Types::Standard qw(Str Int InstanceOf);
use namespace::autoclean;

extends 'STIX::Object';

use constant SCHEMA =>
    'https://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/file.json#/definitions/windows-pe-optional-header-type';

use constant PROPERTIES => (qw(
    magic_hex major_linker_version minor_linker_version size_of_code
    size_of_initialized_data size_of_uninitialized_data address_of_entry_point
    base_of_code base_of_data image_base section_alignment file_alignment
    major_os_version minor_os_version major_image_version minor_image_version
    major_subsystem_version minor_subsystem_version win32_version_value_hex
    size_of_image size_of_headers checksum_hex subsystem_hex
    dll_characteristics_hex size_of_stack_reserve size_of_stack_commit
    size_of_heap_reserve size_of_heap_commit loader_flags_hex
    number_of_rva_and_sizes hashes
));

has magic_hex => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Hex'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Hex->new($_[0]) }
);

has major_linker_version       => (is => 'rw', isa => Int);
has minor_linker_version       => (is => 'rw', isa => Int);
has size_of_code               => (is => 'rw', isa => Int);
has size_of_initialized_data   => (is => 'rw', isa => Int);
has size_of_uninitialized_data => (is => 'rw', isa => Int);
has address_of_entry_point     => (is => 'rw', isa => Int);
has base_of_code               => (is => 'rw', isa => Int);
has base_of_data               => (is => 'rw', isa => Int);
has image_base                 => (is => 'rw', isa => Int);
has section_alignment          => (is => 'rw', isa => Int);
has file_alignment             => (is => 'rw', isa => Int);
has major_os_version           => (is => 'rw', isa => Int);
has minor_os_version           => (is => 'rw', isa => Int);
has major_image_version        => (is => 'rw', isa => Int);
has minor_image_version        => (is => 'rw', isa => Int);
has major_subsystem_version    => (is => 'rw', isa => Int);
has minor_subsystem_version    => (is => 'rw', isa => Int);

has win32_version_value_hex => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Hex'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Hex->new($_[0]) }
);

has size_of_image   => (is => 'rw', isa => Int);
has size_of_headers => (is => 'rw', isa => Int);

has checksum_hex => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Hex'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Hex->new($_[0]) }
);

has subsystem_hex => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Hex'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Hex->new($_[0]) }
);

has dll_characteristics_hex => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Hex'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Hex->new($_[0]) }
);

has size_of_stack_reserve => (is => 'rw', isa => Int);
has size_of_stack_commit  => (is => 'rw', isa => Int);
has size_of_heap_reserve  => (is => 'rw', isa => Int);
has size_of_heap_commit   => (is => 'rw', isa => Int);

has loader_flags_hex => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Hex'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Hex->new($_[0]) }
);

has number_of_rva_and_sizes => (is => 'rw', isa => Int);
has hashes                  => (is => 'rw', isa => InstanceOf ['STIX::Common::Hashes']);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Type::WindowsPEOptionalHeader - STIX Cyber-observable Object (SCO) - windows PE Optional Header Type

=head1 SYNOPSIS

    use STIX::Observable::Type::WindowsPEOptionalHeader;

    my $windows_pe_optional_header_type = STIX::Observable::Type::WindowsPEOptionalHeader->new();


=head1 DESCRIPTION

The Windows PE Optional Header type represents the properties of the PE
optional header.


=head2 METHODS

L<STIX::Observable::Type::WindowsPEOptionalHeader> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Observable::Type::WindowsPEOptionalHeader->new(%properties)

Create a new instance of L<STIX::Observable::Type::WindowsPEOptionalHeader>.

=item $windows_pe_optional_header_type->address_of_entry_point

Specifies the address of the entry point relative to the image base when
the executable is loaded into memory.

=item $windows_pe_optional_header_type->base_of_code

Specifies the address that is relative to the image base of the
beginning-of-code section when it is loaded into memory.

=item $windows_pe_optional_header_type->base_of_data

Specifies the address that is relative to the image base of the
beginning-of-data section when it is loaded into memory.

=item $windows_pe_optional_header_type->checksum_hex

Specifies the checksum of the PE binary.

=item $windows_pe_optional_header_type->dll_characteristics_hex

Specifies the flags that characterize the PE binary.

=item $windows_pe_optional_header_type->file_alignment

Specifies the factor (in bytes) that is used to align the raw data of
sections in the image file.

=item $windows_pe_optional_header_type->hashes

Specifies any hashes that were computed for the optional header
(see L<STIX::Common::Hashes>).

=item $windows_pe_optional_header_type->image_base

Specifies the preferred address of the first byte of the image when loaded
into memory.

=item $windows_pe_optional_header_type->loader_flags_hex

Specifies the reserved loader flags.

=item $windows_pe_optional_header_type->magic_hex

Specifies the unsigned integer that indicates the type of the PE binary.

=item $windows_pe_optional_header_type->major_image_version

Specifies the major version number of the image.

=item $windows_pe_optional_header_type->major_linker_version

Specifies the linker major version number.

=item $windows_pe_optional_header_type->major_os_version

Specifies the major version number of the required operating system.

=item $windows_pe_optional_header_type->major_subsystem_version

Specifies the major version number of the subsystem.

=item $windows_pe_optional_header_type->minor_image_version

Specifies the minor version number of the image.

=item $windows_pe_optional_header_type->minor_linker_version

Specifies the linker minor version number.

=item $windows_pe_optional_header_type->minor_os_version

Specifies the minor version number of the required operating system.

=item $windows_pe_optional_header_type->minor_subsystem_version

Specifies the minor version number of the subsystem.

=item $windows_pe_optional_header_type->number_of_rva_and_sizes

Specifies the number of data-directory entries in the remainder of the
optional header.

=item $windows_pe_optional_header_type->section_alignment

Specifies the alignment (in bytes) of PE sections when they are loaded into
memory.

=item $windows_pe_optional_header_type->size_of_code

Specifies the size of the code (text) section. If there are multiple such
sections, this refers to the sum of the sizes of each section.

=item $windows_pe_optional_header_type->size_of_headers

Specifies the combined size of the MS-DOS, PE header, and section headers,
rounded up a multiple of the value specified in the file_alignment header.

=item $windows_pe_optional_header_type->size_of_heap_commit

Specifies the size of the local heap space to commit.

=item $windows_pe_optional_header_type->size_of_heap_reserve

Specifies the size of the local heap space to reserve.

=item $windows_pe_optional_header_type->size_of_image

Specifies the size, in bytes, of the image, including all headers, as the
image is loaded in memory.

=item $windows_pe_optional_header_type->size_of_initialized_data

Specifies the size of the initialized data section. If there are multiple
such sections, this refers to the sum of the sizes of each section.

=item $windows_pe_optional_header_type->size_of_stack_commit

Specifies the size of the stack to commit.

=item $windows_pe_optional_header_type->size_of_stack_reserve

Specifies the size of the stack to reserve

=item $windows_pe_optional_header_type->size_of_uninitialized_data

Specifies the size of the uninitialized data section. If there are multiple
such sections, this refers to the sum of the sizes of each section.

=item $windows_pe_optional_header_type->subsystem_hex

Specifies the subsystem (e.g., GUI, device driver, etc.) that is required
to run this image.

=item $windows_pe_optional_header_type->win32_version_value_hex

Specifies the reserved win32 version value.

=back


=head2 HELPERS

=over

=item $windows_pe_optional_header_type->TO_JSON

Helper for JSON encoders.

=item $windows_pe_optional_header_type->to_hash

Return the object HASH.

=item $windows_pe_optional_header_type->to_string

Encode the object in JSON.

=item $windows_pe_optional_header_type->validate

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
