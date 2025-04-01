package SBOM::CycloneDX::Definitions;

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

has standards => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Standard']],
    default => sub { SBOM::CycloneDX::List->new }
);

sub TO_JSON {

    my $self = shift;

    my $json = {standards => $self->standards};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Definitions - Definitions

=head1 SYNOPSIS

    SBOM::CycloneDX::Definitions->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Definitions> is a collection of reusable objects that are
defined and may be used elsewhere in the BOM.

=head2 METHODS

L<SBOM::CycloneDX::Definitions> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Definitions->new( %PARAMS )

Properties:

=over

=item C<standards>, The list of standards which may consist of regulations,
industry or organizational-specific standards, maturity models, best
practices, or any other requirements which can be evaluated against or
attested to.

=back

=item $definitions->standards

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
