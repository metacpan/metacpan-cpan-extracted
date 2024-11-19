package STIX::Observable::EmailAddr;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str InstanceOf);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/email-addr.json';

use constant PROPERTIES => (
    qw(type id),
    qw(spec_version object_marking_refs granular_markings defanged extensions),
    qw(value display_name belongs_to_ref)
);

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'email-addr';

has value          => (is => 'rw', isa => Str, required => 1);
has display_name   => (is => 'rw', isa => Str);
has belongs_to_ref => (is => 'rw', isa => InstanceOf ['STIX::Observable::UserAccount']);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::EmailAddr - STIX Cyber-observable Object (SCO) - Email Address

=head1 SYNOPSIS

    use STIX::Observable::EmailAddr;

    my $email_addr = STIX::Observable::EmailAddr->new();


=head1 DESCRIPTION

The Email Address Object represents a single email address.


=head2 METHODS

L<STIX::Observable::EmailAddr> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::EmailAddr->new(%properties)

Create a new instance of L<STIX::Observable::EmailAddr>.

=item $email_addr->belongs_to_ref

Specifies the user account that the email address belongs to, as a
reference to a User Account Object.

=item $email_addr->display_name

Specifies a single email display name, i.e., the name that is displayed to
the human user of a mail application.

=item $email_addr->id

=item $email_addr->type

The value of this property MUST be C<email-addr>.

=item $email_addr->value

Specifies a single email address. This MUST not include the display name.

=back


=head2 HELPERS

=over

=item $email_addr->TO_JSON

Encode the object in JSON.

=item $email_addr->to_hash

Return the object HASH.

=item $email_addr->to_string

Encode the object in JSON.

=item $email_addr->validate

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
