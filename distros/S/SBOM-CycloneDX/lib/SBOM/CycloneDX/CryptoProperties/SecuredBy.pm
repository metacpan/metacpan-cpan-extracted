package SBOM::CycloneDX::CryptoProperties::SecuredBy;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(Str);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has mechanism => (is => 'rw', isa => Str);

# bom-ref like
has algorithm_ref => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });


sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{mechanism}    = $self->mechanism     if $self->mechanism;
    $json->{algorithmRef} = $self->algorithm_ref if @{$self->algorithm_ref};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::CryptoProperties::SecuredBy - The mechanism by which the cryptographic asset is secured by

=head1 SYNOPSIS


=head1 DESCRIPTION

L<SBOM::CycloneDX::CryptoProperties::SecuredBy> specifies the mechanism by which the cryptographic asset is secured by.

=head2 METHODS

L<SBOM::CycloneDX::CryptoProperties::SecuredBy> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::CryptoProperties::SecuredBy->new( %PARAMS )

Properties:

=over

=item * C<mechanism>, Specifies the mechanism by which the cryptographic
asset is secured by (examples C<HSM>, C<TPM>, C<SGX>, C<Software>, C<None>)

=item * C<algorithm_ref>, The list of bom-ref to the algorithm.

=back

=item $secured_by->mechanism

=item $secured_by->algorithm_ref

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
