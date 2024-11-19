package STIX::Observable::Software;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use STIX::Common::OpenVocabulary;
use Types::Standard qw(Str);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/software.json';

use constant PROPERTIES => (
    qw(type id),
    qw(spec_version object_marking_refs granular_markings defanged extensions),
    qw(name cpe swid languages vendor version)
);

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'software';

has name      => (is => 'rw', isa => Str, required => 1);
has cpe       => (is => 'rw', isa => Str);
has swid      => (is => 'rw', isa => Str);
has languages => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });
has version   => (is => 'rw', isa => Str);
has vendor    => (is => 'rw', isa => Str);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Software - STIX Cyber-observable Object (SCO) - Software

=head1 SYNOPSIS

    use STIX::Observable::Software;

    my $software = STIX::Observable::Software->new();


=head1 DESCRIPTION

The Software Object represents high-level properties associated with
software, including software products.


=head2 METHODS

L<STIX::Observable::Software> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::Software->new(%properties)

Create a new instance of L<STIX::Observable::Software>.

=item $software->cpe

Specifies the Common Platform Enumeration (CPE) entry for the software, if
available. The value for this property MUST be a CPE v2.3 entry from the
official NVD CPE Dictionary.

=item $software->id

=item $software->languages

Specifies the languages supported by the software. The value of each list
member MUST be an ISO 639-2 language code.

=item $software->name

Specifies the name of the software.

=item $software->swid

Specifies the Software Identification (SWID) Tags entry for the software,
if available.

=item $software->type

The value of this property MUST be C<software>.

=item $software->vendor

Specifies the name of the vendor of the software.

=item $software->version

Specifies the version of the software.

=back


=head2 HELPERS

=over

=item $software->TO_JSON

Encode the object in JSON.

=item $software->to_hash

Return the object HASH.

=item $software->to_string

Encode the object in JSON.

=item $software->validate

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
