package STIX::Observable::WindowsRegistryKey;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use Types::Standard qw(Str Int InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/windows-registry-key.json';

use constant PROPERTIES => (
    qw(type id),
    qw(spec_version object_marking_refs granular_markings defanged extensions),
    qw(key values modified_time creator_user_ref number_of_subkeys),
);

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'windows-registry-key';

has key => (is => 'rw', isa => Str);

has values => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Observable::Type::WindowsRegistryValue']],
    default => sub { STIX::Common::List->new }
);

has modified_time => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has creator_user_ref  => (is => 'rw', isa => InstanceOf ['STIX::Observable::UserAccount']);
has number_of_subkeys => (is => 'rw', isa => Int);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::WindowsRegistryKey - STIX Cyber-observable Object (SCO) - Windows Registry Key

=head1 SYNOPSIS

    use STIX::Observable::WindowsRegistryKey;

    my $windows_registry_key = STIX::Observable::WindowsRegistryKey->new();


=head1 DESCRIPTION

The Registry Key Object represents the properties of a Windows registry
key.


=head2 METHODS

L<STIX::Observable::WindowsRegistryKey> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::WindowsRegistryKey->new(%properties)

Create a new instance of L<STIX::Observable::WindowsRegistryKey>.

=item $windows_registry_key->creator_user_ref

Specifies a reference to a user account, represented as a User Account
Object, that created the registry key.

=item $windows_registry_key->id

=item $windows_registry_key->key

Specifies the full registry key including the hive.

=item $windows_registry_key->modified_time

Specifies the last date/time that the registry key was modified.

=item $windows_registry_key->number_of_subkeys

Specifies the number of subkeys contained under the registry key.

=item $windows_registry_key->type

The value of this property MUST be C<windows-registry-key>.

=item $windows_registry_key->values

Specifies the values found under the registry key.

=back


=head2 HELPERS

=over

=item $windows_registry_key->TO_JSON

Encode the object in JSON.

=item $windows_registry_key->to_hash

Return the object HASH.

=item $windows_registry_key->to_string

Encode the object in JSON.

=item $windows_registry_key->validate

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
