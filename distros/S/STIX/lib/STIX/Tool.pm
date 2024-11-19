package STIX::Tool;

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
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/tool.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(name description tool_types aliases kill_chain_phases tool_version)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'tool';

has name => (is => 'rw', isa => Str, required => 1);
has description => (is => 'rw', isa => Str);

has tool_types => (
    is      => 'rw',
    isa     => ArrayLike [Enum [STIX::Common::OpenVocabulary->TOOL_TYPE()]],
    default => sub { STIX::Common::List->new }
);

has aliases => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });
has kill_chain_phases => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Common::KillChainPhase']],
    default => sub { STIX::Common::List->new }
);
has tool_version => (is => 'rw', isa => Str);

1;

=encoding utf-8

=head1 NAME

STIX::Tool - STIX Domain Object (SDO) - Tool

=head1 SYNOPSIS

    use STIX::Tool;

    my $tool = STIX::Tool->new();


=head1 DESCRIPTION

Tools are legitimate software that can be used by threat actors to perform
attacks.


=head2 METHODS

L<STIX::Tool> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Tool->new(%properties)

Create a new instance of L<STIX::Tool>.

=item $tool->aliases

Alternative names used to identify this Tool.

=item $tool->description

Provides more context and details about the Tool object.

=item $tool->id

=item $tool->kill_chain_phases

The list of kill chain phases for which this Tool instance can be used.

=item $tool->name

The name used to identify the Tool.

=item $tool->tool_types

The kind(s) of tool(s) being described. (See C<TOOL_TYPE> in
L<STIX::Common::OpenVocabulary>)

=item $tool->tool_version

The version identifier associated with the tool.

=item $tool->type

The type of this object, which MUST be the literal C<tool>.

=back


=head2 HELPERS

=over

=item $tool->TO_JSON

Encode the object in JSON.

=item $tool->to_hash

Return the object HASH.

=item $tool->to_string

Encode the object in JSON.

=item $tool->validate

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
