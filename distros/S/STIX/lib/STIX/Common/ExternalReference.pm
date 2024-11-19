package STIX::Common::ExternalReference;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str InstanceOf);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/common/external-reference.json';

use constant PROPERTIES => qw(source_name description url hashes external_id);

has source_name => (is => 'rw', isa => Str, required => 1);
has description => (is => 'rw', isa => Str);
has url         => (is => 'rw', isa => Str);
has hashes      => (is => 'rw', isa => InstanceOf ['STIX::Common::Hashes']);
has external_id => (is => 'rw', isa => Str);

1;

=encoding utf-8

=head1 NAME

STIX::Common::ExternalReference - STIX External Reference

=head1 SYNOPSIS

    use STIX::Common::ExternalReference;

    my $external_reference = STIX::Common::ExternalReference->new();


=head1 DESCRIPTION

External references are used to describe pointers to information
represented outside of STIX.


=head2 METHODS

L<STIX::Common::ExternalReference> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Common::ExternalReference->new(%properties)

Create a new instance of L<STIX::Common::ExternalReference>.

=item $external_reference->description

A human readable description

=item $external_reference->hashes

Specifies a dictionary of hashes for the file.

=item $external_reference->url

A URL reference to an external resource.

=back


=head2 HELPERS

=over

=item $external_reference->TO_JSON

Helper for JSON encoders.

=item $external_reference->to_hash

Return the object HASH.

=item $external_reference->to_string

Encode the object in JSON.

=item $external_reference->validate

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
