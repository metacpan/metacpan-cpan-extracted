package STIX::Observable::DomainName;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/domain-name.json';

use constant PROPERTIES => (
    qw(type id),
    qw(spec_version object_marking_refs granular_markings defanged extensions),
    qw(value resolves_to_refs)
);

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'domain-name';

has value => (is => 'rw', isa => Str, required => 1);

has resolves_to_refs => (
    is  => 'rw',
    isa => ArrayLike [
        InstanceOf [
            'STIX::Cbservable::IPv4Addr',   'STIX::Observable::IPv6Addr',
            'STIX::Observable::DomainName', 'STIX::Common::Identifier'
        ]
    ],
    default => sub { STIX::Common::List->new }
);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::DomainName - STIX Cyber-observable Object (SCO) - Domain Name

=head1 SYNOPSIS

    use STIX::Observable::DomainName;

    my $domain_name = STIX::Observable::DomainName->new();


=head1 DESCRIPTION

The Domain Name represents the properties of a network domain name.


=head2 METHODS

L<STIX::Observable::DomainName> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::DomainName->new(%properties)

Create a new instance of L<STIX::Observable::DomainName>.

=item $domain_name->id

=item $domain_name->resolves_to_refs

Specifies a list of references to one or more IP addresses or domain names
that the domain name resolves to.

=item $domain_name->type

The value of this property MUST be C<domain-name>.

=item $domain_name->value

Specifies the value of the domain name.

=back


=head2 HELPERS

=over

=item $domain_name->TO_JSON

Encode the object in JSON.

=item $domain_name->to_hash

Return the object HASH.

=item $domain_name->to_string

Encode the object in JSON.

=item $domain_name->validate

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
