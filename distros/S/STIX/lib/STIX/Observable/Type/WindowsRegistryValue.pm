package STIX::Observable::Type::WindowsRegistryValue;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::OpenVocabulary;

use Moo;
use Types::Standard qw(Str Enum);
use namespace::autoclean;

extends 'STIX::Object';

use constant SCHEMA =>
    'https://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/windows-registry-key.json#/definitions/windows-registry-value-type';

use constant PROPERTIES => (qw(name data data_type));

has name      => (is => 'rw', isa => Str);
has data      => (is => 'rw', isa => Str);
has data_type => (is => 'rw', isa => Enum [STIX::Common::Enum->WINDOWS_REGISTRY_DATATYPE()]);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Type::WindowsRegistryValue - STIX Cyber-observable Object (SCO) - Windows Registry Value

=head1 SYNOPSIS

    use STIX::Observable::Type::WindowsRegistryValue;

    my $windows_registry_value_type = STIX::Observable::Type::WindowsRegistryValue->new();


=head1 DESCRIPTION

Specifies the values found under the registry key.


=head2 METHODS

L<STIX::Observable::Type::WindowsRegistryValue> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Observable::Type::WindowsRegistryValue->new(%properties)

Create a new instance of L<STIX::Observable::Type::WindowsRegistryValue>.

=item $windows_registry_value_type->data

Specifies the data contained in the registry value.

=item $windows_registry_value_type->data_type

Specifies the registry (REG_*) data type used in the registry value.

=item $windows_registry_value_type->name

Specifies the name of the registry value. For specifying the default value
in a registry key, an empty string MUST be used.

=back


=head2 HELPERS

=over

=item $windows_registry_value_type->TO_JSON

Helper for JSON encoders.

=item $windows_registry_value_type->to_hash

Return the object HASH.

=item $windows_registry_value_type->to_string

Encode the object in JSON.

=item $windows_registry_value_type->validate

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
