package STIX::Campaign;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Common::Properties';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/campaign.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(name description aliases first_seen last_seen objective)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'campaign';

has name        => (is => 'rw', isa => Str, required => 1);
has description => (is => 'rw', isa => Str);
has aliases     => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });

has first_seen => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has last_seen => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has objective => (is => 'rw', isa => Str);

1;


=encoding utf-8

=head1 NAME

STIX::Campaign - STIX Domain Object (SDO) - Campaign

=head1 SYNOPSIS

    use STIX::Campaign;

    my $campaign = STIX::Campaign->new();


=head1 DESCRIPTION

A Campaign is a grouping of adversary behavior that describes a set of
malicious activities or attacks that occur over a period of time against a
specific set of targets.


=head2 METHODS

L<STIX::Campaign> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Campaign->new(%properties)

Create a new instance of L<STIX::Campaign>.

=item $campaign->aliases

Alternative names used to identify this campaign.

=item $campaign->description

A description that provides more details and context about the Campaign,
potentially including its purpose and its key characteristics.

=item $campaign->first_seen

The time that this Campaign was first seen.

=item $campaign->id

=item $campaign->last_seen

The time that this Campaign was last seen.

=item $campaign->name

The name used to identify the Campaign.

=item $campaign->objective

This field defines the Campaign’s primary goal, objective, desired outcome,
or intended effect.

=item $campaign->type

The type of this object, which MUST be the literal C<campaign>.

=back


=head2 HELPERS

=over

=item $campaign->TO_JSON

Encode the object in JSON.

=item $campaign->to_hash

Return the object HASH.

=item $campaign->to_string

Encode the object in JSON.

=item $campaign->validate

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
