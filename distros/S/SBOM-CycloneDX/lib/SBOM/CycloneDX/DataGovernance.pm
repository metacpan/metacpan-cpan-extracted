package SBOM::CycloneDX::DataGovernance;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has custodians => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::DataGovernanceResponsibleParty']],
    default => sub { SBOM::CycloneDX::List->new }
);

has stewards => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::DataGovernanceResponsibleParty']],
    default => sub { SBOM::CycloneDX::List->new }
);

has owners => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::DataGovernanceResponsibleParty']],
    default => sub { SBOM::CycloneDX::List->new }
);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{custodians} = $self->custodians if @{$self->custodians};
    $json->{stewards}   = $self->stewards   if @{$self->stewards};
    $json->{owners}     = $self->owners     if @{$self->owners};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::DataGovernance - Data Governance

=head1 SYNOPSIS

    SBOM::CycloneDX::DataGovernance->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::DataGovernance> provides the data governance captures information
regarding data ownership, stewardship, and custodianship, providing
insights into the individuals or entities responsible for managing,
overseeing, and safeguarding the data throughout its lifecycle.

=head2 METHODS

L<SBOM::CycloneDX::DataGovernance> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::DataGovernance->new( %PARAMS )

Properties:

=over

=item C<custodians>, Data custodians are responsible for the safe custody,
transport, and storage of data.

=item C<owners>, Data owners are concerned with risk and appropriate access
to data.

=item C<stewards>, Data stewards are responsible for data content, context,
and associated business rules.

=back

=item $data_governance->custodians

=item $data_governance->owners

=item $data_governance->stewards

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SBOM-CycloneDX>

    git clone https://github.com/giterlizzi/perl-SBOM-CycloneDX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
