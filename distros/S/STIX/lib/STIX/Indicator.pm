package STIX::Indicator;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use STIX::Common::OpenVocabulary;
use Types::Standard qw(Str Enum InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Common::Properties';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/indicator.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(name description indicator_types pattern pattern_type pattern_version valid_from valid_until kill_chain_phases)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'indicator';

has name => (is => 'rw', required => 1, isa => Str);
has description => (is => 'rw', isa => Str);

has indicator_types => (
    is      => 'rw',
    isa     => ArrayLike [Enum [STIX::Common::OpenVocabulary->INDICATOR_TYPE()]],
    default => sub { STIX::Common::List->new }
);

has pattern         => (is => 'rw', required => 1, isa => Str);
has pattern_type    => (is => 'rw', required => 1, isa => Enum [STIX::Common::OpenVocabulary->PATTERN_TYPE()]);
has pattern_version => (is => 'rw', isa      => Str);

has valid_from => (
    is       => 'rw',
    required => 1,
    isa      => InstanceOf ['STIX::Common::Timestamp'],
    coerce   => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has valid_until => (is => 'rw', isa => InstanceOf ['STIX::Common::Timestamp']);
has kill_chain_phases => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Common::KillChainPhase']],
    default => sub { STIX::Common::List->new }
);

1;


=encoding utf-8

=head1 NAME

STIX::Indicator - STIX Domain Object (SDO) - Indicator

=head1 SYNOPSIS

    use STIX::Indicator;

    my $indicator = STIX::Indicator->new();


=head1 DESCRIPTION

Indicators contain a pattern that can be used to detect suspicious or
malicious cyber activity.


=head2 METHODS

L<STIX::Indicator> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Indicator->new(%properties)

Create a new instance of L<STIX::Indicator>.

=item $indicator->description

A description that provides the recipient with context about this Indicator
potentially including its purpose and its key characteristics.

=item $indicator->id

=item $indicator->indicator_types

This field is an Open Vocabulary that specifies the type of indicator.
(See C<INDICATOR_TYPE> in L<STIX::Common::OpenVocabulary>)

=item $indicator->kill_chain_phases

The phases of the kill chain that this indicator detects.

=item $indicator->name

The name used to identify the Indicator.

=item $indicator->pattern

The detection pattern for this indicator.

=item $indicator->pattern_type

The type of pattern used in this indicator.
(See C<PATTERN_TYPE> in L<STIX::Common::OpenVocabulary>)

=item $indicator->pattern_version

The version of the pattern that is used.

=item $indicator->type

The type of this object, which MUST be the literal C<indicator>.

=item $indicator->valid_from

The time from which this indicator should be considered valuable
intelligence.

=item $indicator->valid_until

The time at which this indicator should no longer be considered valuable
intelligence.

=back


=head2 HELPERS

=over

=item $indicator->TO_JSON

Encode the object in JSON.

=item $indicator->to_hash

Return the object HASH.

=item $indicator->to_string

Encode the object in JSON.

=item $indicator->validate

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
