package SBOM::CycloneDX::BomRef;

use 5.010001;
use strict;
use warnings;
use utf8;

use Carp;
use Time::Piece;

use overload '""' => \&to_string, fallback => 1;

use Moo;

around BUILDARGS => sub {

    my ($orig, $class, @args) = @_;

    return {value => $args[0]} if @args == 1;
    return $class->$orig(@args);

};

has value => (is => 'rw', required => 1);

sub to_string { shift->TO_JSON }

sub TO_JSON { shift->value }

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::BomRef - BOM-ref representation for CycloneDX

=head1 SYNOPSIS

    $component->bom_ref(SBOM::CycloneDX::BomRef->new('app-component'));


=head1 DESCRIPTION

L<SBOM::CycloneDX::BomRef> represents the BOM reference in L<SBOM::CycloneDX>.

=head2 METHODS

=over

=item SBOM::CycloneDX::BomRef->new( %PARAMS )

=item $bom_ref->value

=item $bom_ref->to_string

=item $bom_ref->TO_JSON

Return BOM ref.

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
