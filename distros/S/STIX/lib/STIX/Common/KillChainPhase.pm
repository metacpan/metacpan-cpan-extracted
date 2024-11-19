package STIX::Common::KillChainPhase;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/common/kill-chain-phase.json';

use constant PROPERTIES => qw(kill_chain_name phase_name);

has kill_chain_name => (is => 'rw', required => 1, isa => Str);
has phase_name      => (is => 'rw', required => 1, isa => Str);

1;

=encoding utf-8

=head1 NAME

STIX::Common::KillChainPhase - STIX Kill Chain Phase

=head1 SYNOPSIS

    use STIX::Common::KillChainPhase;

    my $kill_chain_phase = STIX::Common::KillChainPhase->new();


=head1 DESCRIPTION

The C<kill-chain-phase> represents a phase in a kill chain.


=head2 METHODS

L<STIX::Common::KillChainPhase> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Common::KillChainPhase->new(%properties)

Create a new instance of L<STIX::Common::KillChainPhase>.

=item $kill_chain_phase->kill_chain_name

The name of the kill chain.

=item $kill_chain_phase->phase_name

The name of the phase in the kill chain.

=back


=head2 HELPERS

=over

=item $kill_chain_phase->TO_JSON

Helper for JSON encoders.

=item $kill_chain_phase->to_hash

Return the object HASH.

=item $kill_chain_phase->to_string

Encode the object in JSON.

=item $kill_chain_phase->validate

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
