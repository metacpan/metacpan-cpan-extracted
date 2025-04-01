package SBOM::CycloneDX::Declarations::Targets;

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

has organizations => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::OrganizationalEntity']],
    default => sub { SBOM::CycloneDX::List->new }
);

has components => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Component']],
    default => sub { SBOM::CycloneDX::List->new }
);

has services => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Service']],
    default => sub { SBOM::CycloneDX::List->new }
);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{organizations} = $self->organizations if @{$self->organizations};
    $json->{components}    = $self->components    if @{$self->components};
    $json->{services}      = $self->services      if @{$self->services};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Declarations::Targets - Targets

=head1 SYNOPSIS

    SBOM::CycloneDX::Declarations::Targets->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Declarations::Targets> provide the list of targets which claims
are made against.

=head2 METHODS

L<SBOM::CycloneDX::Declarations::Targets> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Declarations::Targets->new( %PARAMS )

Properties:

=over

=item C<components>, The list of components which claims are made against.

=item C<organizations>, The list of organizations which claims are made
against.

=item C<services>, The list of services which claims are made against.

=back

=item $targets->components

=item $targets->organizations

=item $targets->services

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
