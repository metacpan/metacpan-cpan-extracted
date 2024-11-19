package STIX::Common::ExtensionDefinition;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::Enum;
use STIX::Common::List;
use Types::Standard qw(Str Enum);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Common::Properties';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/common/extension-definition.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified created_by_ref),
    qw(revoked labels external_references object_marking_refs granular_markings),
    qw(name description schema version extension_types extension_properties)
);

use constant STIX_OBJECT_TYPE => 'extension-definition';

has name        => (is => 'rw', isa => Str, required => 1);
has description => (is => 'rw', isa => Str);
has schema      => (is => 'rw', isa => Str, required => 1);
has version     => (is => 'rw', isa => Str, required => 1);

has extension_types => (
    is       => 'rw',
    isa      => ArrayLike [Enum [STIX::Common::Enum->EXTENSION_TYPE()]],
    required => 1,
    default  => sub { [] }
);

has extension_properties => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });

1;

=encoding utf-8

=head1 NAME

STIX::Common::ExtensionDefinition - STIX Extension Definition

=head1 SYNOPSIS

    use STIX::Common::ExtensionDefinition;
    use STIX::Indicator;

    my $extension_definition = STIX::Common::ExtensionDefinition->new(
        extension_types => ['property-extension'],
        name            => 'Extension Foo 1',
        schema          => 'https://www.example.com/schema-foo-1/v1/',
        version         => '1.2.1',
    );

    my $indicator = STIX::Indicator->new(
        name         => 'File hash for Poison Ivy variant',
        description  => 'This file hash indicates that a sample of Poison Ivy is present.',
        labels       => ['malicious-activity'],
        pattern      => q{[file:hashes.'SHA-256' = 'ef537f25c895bfa782526529a9b63d97aa631564d5d789c2b765448c8635fb6c']},
        pattern_type => 'stix',
        valid_from   => '2014-02-20T09:00:00.000000Z',
        extensions   => {$extension_definition->id => {extension_type => 'property-extension', rank => 5, toxicity => 8}}
    );


=head1 DESCRIPTION

The STIX Extension Definition object allows producers of threat
intelligence to extend existing STIX objects or to create entirely new STIX
objects in a standardized way.


=head2 METHODS

L<STIX::Common::ExtensionDefinition> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Common::ExtensionDefinition->new(%properties)

Create a new instance of L<STIX::Common::ExtensionDefinition>.

=item $extension_definition->description

A detailed explanation of what data the extension conveys and how it is
intended to be used.

=item $extension_definition->extension_properties

The list of new property names that are added to an object by this
extension

=item $extension_definition->extension_types

Which extension types are contained within this extension.

=item $extension_definition->id

=item $extension_definition->name

A name used for display purposes during execution, development, or
debugging.

=item $extension_definition->schema

The normative definition of the extension, either as a URL or as plain text
explaining the definition.

=item $extension_definition->type

The type of this object, which MUST be the literal C<extension-definition>.

=item $extension_definition->version

The version of this extension.

=back


=head2 HELPERS

=over

=item $extension_definition->TO_JSON

Helper for JSON encoders.

=item $extension_definition->to_hash

Return the object HASH.

=item $extension_definition->to_string

Encode the object in JSON.

=item $extension_definition->validate

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
