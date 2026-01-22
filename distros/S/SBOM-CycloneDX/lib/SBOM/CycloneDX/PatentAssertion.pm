package SBOM::CycloneDX::PatentAssertion;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::Enum;
use SBOM::CycloneDX::List;

use Types::Standard qw(Str InstanceOf Enum);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has assertion_type => (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->values('PATENT_ASSERTION_TYPE')], required => 1);

has patent_refs => (
    is      => 'rw',
    isa     => ArrayLike [Str | InstanceOf ['SBOM::CycloneDX::BomRef']],
    default => sub { SBOM::CycloneDX::List->new }
);

has asserter => (
    is  => 'rw',
    isa => (
        InstanceOf ['SBOM::CycloneDX::OrganizationalContact'] | InstanceOf ['SBOM::CycloneDX::OrganizationalEntity']
            | InstanceOf ['SBOM::CycloneDX::BomRef']
    ),
    required => 1
);

has notes => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{'bom-ref'}     = $self->bom_ref        if ($self->bom_ref);
    $json->{assertionType} = $self->assertion_type if ($self->assertion_type);
    $json->{patentRefs}    = $self->patent_refs    if (@{$self->patent_refs});
    $json->{asserter}      = $self->asserter       if ($self->asserter);
    $json->{notes}         = $self->notes          if ($self->notes);

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::PatentAssertion - Patent Assertion

=head1 SYNOPSIS

    SBOM::CycloneDX::PatentAssertion->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::PatentAssertion> An assertion linking a patent or patent
family to this component or service.

=head2 METHODS

L<SBOM::CycloneDX::PatentAssertion> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::PatentAssertion->new( %PARAMS )

Properties:

=over

=item * C<asserter>, One of a L<SBOM::CycloneDX::OrganizationalEntity>, L<SBOM::CycloneDX::OrganizationalContact> or L<SBOM::CycloneDX::BomRef> object.

=item * C<assertion_type>, The type of assertion being made about the patent
or patent family. Examples include ownership, licensing, and standards
inclusion.

See L<SBOM::CycloneDX::Enum::PatentAssertionType>.

=item * C<bom_ref>, A reference to the patent or patent family object within
the BOM. This must match the L<SBOM::CycloneDX::BomRef> of a L<SBOM::CycloneDX::Patent> or C L<SBOM::CycloneDX::PatentFamily>
object.

=item * C<notes>, Additional notes or clarifications regarding the assertion,
if necessary. For example, geographical restrictions, duration, or
limitations of a license.

=item * C<patent_refs>, A list of BOM references (C<bom-ref>) linking to
patents or patent families associated with this assertion.

=back

=item $patent_assertion->asserter

=item $patent_assertion->assertion_type

=item $patent_assertion->bom_ref

=item $patent_assertion->notes

=item $patent_assertion->patent_refs

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
