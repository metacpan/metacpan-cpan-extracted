package SBOM::CycloneDX::Metadata::Lifecycle;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::Enum;

use Types::Standard qw(Enum Str);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

sub BUILD {
    my ($self, $args) = @_;
    Carp::croak('"phase" and "name" cannot be used at the same time') if exists $args->{phase} && exists $args->{name};
    Carp::croak('"description" without "name"') if exists $args->{phase} && exists $args->{description};
}

has phase       => (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->values('LIFECYCLE_PHASE')]);
has name        => (is => 'rw', isa => Str);
has description => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{phase}       = $self->phase       if $self->phase;
    $json->{name}        = $self->name        if $self->name;
    $json->{description} = $self->description if $self->description;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Metadata::Lifecycle - Lifecycle

=head1 SYNOPSIS

    SBOM::CycloneDX::Metadata::Lifecycle->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Metadata::Lifecycle> provides the product lifecycle(s) that
this BOM represents.

=head2 METHODS

L<SBOM::CycloneDX::Metadata::Lifecycle> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Metadata::Lifecycle->new( %PARAMS )

Properties:

=over

=item * C<description>, The name of the lifecycle phase.

=item * C<name>, The description of the lifecycle phase.

=item * C<phase>, A pre-defined phase in the product lifecycle.

=back

=item $lifecycle->description

=item $lifecycle->name

=item $lifecycle->phase

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
