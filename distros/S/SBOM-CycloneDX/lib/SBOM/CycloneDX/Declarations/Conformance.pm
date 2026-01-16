package SBOM::CycloneDX::Declarations::Conformance;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(Str Num);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has score                 => (is => 'rw', isa => Num);
has rationale             => (is => 'rw', isa => Str);
has mitigation_strategies => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });


sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{score}                = $self->score                 if $self->score;
    $json->{rationale}            = $self->rationale             if $self->rationale;
    $json->{mitigationStrategies} = $self->mitigation_strategies if @{$self->mitigation_strategies};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Declarations::Conformance - Conformance

=head1 SYNOPSIS

    SBOM::CycloneDX::Declarations::Conformance->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Declarations::Conformance> provide the conformance of the claim
meeting a requirement.

=head2 METHODS

L<SBOM::CycloneDX::Declarations::Conformance> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Declarations::Conformance->new( %PARAMS )

Properties:

=over

=item C<mitigation_strategies>, The list of  `bom-ref` to the evidence
provided describing the mitigation strategies.

=item C<rationale>, The rationale for the conformance score.

=item C<score>, The conformance of the claim between and inclusive of 0 and
1, where 1 is 100% conformance.

=back

=item $conformance->mitigation_strategies

=item $conformance->rationale

=item $conformance->score

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
