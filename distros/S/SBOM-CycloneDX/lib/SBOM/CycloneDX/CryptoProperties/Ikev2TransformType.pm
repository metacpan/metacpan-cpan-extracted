package SBOM::CycloneDX::CryptoProperties::Ikev2TransformType;

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

# bom-ref like
has encr => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

# bom-ref like
has prf => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

# bom-ref like
has integ => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

# bom-ref like
has ke => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

# bom-ref like
has esn => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

# bom-ref like
has auth => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });


sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{encr}  = $self->encr  if @{$self->encr};
    $json->{prf}   = $self->prf   if @{$self->prf};
    $json->{integ} = $self->integ if @{$self->integ};
    $json->{ke}    = $self->ke    if @{$self->ke};
    $json->{esn}   = $self->esn   if @{$self->esn};
    $json->{auth}  = $self->auth  if @{$self->auth};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::CryptoProperties::Ikev2TransformType - IKEv2 Transform Types

=head1 SYNOPSIS

    SBOM::CycloneDX::CryptoProperties::Ikev2TransformType->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::CryptoProperties::Ikev2TransformType> specifies the IKEv2
transform types supported (types 1-4), defined in RFC 7296 section 3.3.2
(L<https://www.ietf.org/rfc/rfc7296.html#section-3.3.2>), and additional properties.

=head2 METHODS

L<SBOM::CycloneDX::CryptoProperties::Ikev2TransformType> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::CryptoProperties::Ikev2TransformType->new( %PARAMS )

Properties:

=over

=item C<auth>, IKEv2 Authentication method

=item C<encr>, Transform Type 1: encryption algorithms

=item C<esn>, Specifies if an Extended Sequence Number (ESN) is used.

=item C<integ>, Transform Type 3: integrity algorithms

=item C<ke>, Transform Type 4: Key Exchange Method (KE) per RFC
9370 (L<https://www.ietf.org/rfc/rfc9370.html>), formerly called
Diffie-Hellman Group (D-H).

=item C<prf>, Transform Type 2: pseudorandom functions

=back

=item $ikev2_transform_type->auth

=item $ikev2_transform_type->encr

=item $ikev2_transform_type->esn

=item $ikev2_transform_type->integ

=item $ikev2_transform_type->ke

=item $ikev2_transform_type->prf

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
