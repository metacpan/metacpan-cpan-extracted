package STIX::Observable::Type::WindowsPESection;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;
use Types::Standard qw(Str Int InstanceOf);
use namespace::autoclean;

extends 'STIX::Object';

use constant SCHEMA =>
    'https://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/file.json#/definitions/windows-pe-section';

use constant PROPERTIES => (qw(
    name size entropy hashes
));

has name    => (is => 'rw', required => 1, isa => Str);
has size    => (is => 'rw', isa      => Int);
has entropy => (is => 'rw', isa      => Int);
has hashes  => (is => 'rw', isa      => InstanceOf ['STIX::Common::Hashes']);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Type::WindowsPESection - STIX Cyber-observable Object (SCO) - Windows PE Section Value

=head1 SYNOPSIS

    use STIX::Observable::Type::WindowsPESection;

    my $windows_pe_section_type = STIX::Observable::Type::WindowsPESection->new();


=head1 DESCRIPTION

The PE Section type specifies metadata about a PE file section.


=head2 METHODS

L<STIX::Observable::Type::WindowsPESection> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Observable::Type::WindowsPESection->new(%properties)

Create a new instance of L<STIX::Observable::Type::WindowsPESection>.

=item $windows_pe_section_type->entropy

Specifies the calculated entropy for the section, as calculated using the
Shannon algorithm.

=item $windows_pe_section_type->hashes

Specifies any hashes computed over the section (see L<STIX::Common::Hashes>).

=item $windows_pe_section_type->name

Specifies the name of the section.

=item $windows_pe_section_type->size

Specifies the size of the section, in bytes.

=back


=head2 HELPERS

=over

=item $windows_pe_section_type->TO_JSON

Helper for JSON encoders.

=item $windows_pe_section_type->to_hash

Return the object HASH.

=item $windows_pe_section_type->to_string

Encode the object in JSON.

=item $windows_pe_section_type->validate

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
