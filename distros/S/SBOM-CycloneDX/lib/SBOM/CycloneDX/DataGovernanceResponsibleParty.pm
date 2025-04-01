package SBOM::CycloneDX::DataGovernanceResponsibleParty;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

sub BUILD {
    my ($self, $args) = @_;
    Carp::croak('"organization" and "contact" cannot be used at the same time')
        if exists $args->{organization} && exists $args->{contact};
}

has organization => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::OrganizationalEntity']);
has contact      => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::OrganizationalContact']);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{organization} = $self->organization if $self->organization;
    $json->{contact}      = $self->contact      if $self->contact;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::DataGovernanceResponsibleParty - Data Custodians

=head1 SYNOPSIS

    SBOM::CycloneDX::DataGovernanceResponsibleParty->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::DataGovernanceResponsibleParty> provides the data custodians
are responsible for the safe custody, transport, and storage of data.

=head2 METHODS

L<SBOM::CycloneDX::DataGovernanceResponsibleParty> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::DataGovernanceResponsibleParty->new( %PARAMS )

Properties:

=over

=item C<contact>, The individual that is responsible for specific data
governance role(s).

=item C<organization>, The organization that is responsible for specific
data governance role(s).

=back

=item $data_governance_responsible_party->contact

=item $data_governance_responsible_party->organization

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

This software is copyright (c) 2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
