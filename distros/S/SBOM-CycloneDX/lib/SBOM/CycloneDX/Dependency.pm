package SBOM::CycloneDX::Dependency;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has ref => (is => 'rw', isa => Str | InstanceOf ['SBOM::CycloneDX::BomRef'], required => 1);
has depends_on => (
    is      => 'rw',
    isa     => ArrayLike [Str | InstanceOf ['SBOM::CycloneDX::BomRef']],
    default => sub { SBOM::CycloneDX::List->new }
);
has provides => (
    is      => 'rw',
    isa     => ArrayLike [Str | InstanceOf ['SBOM::CycloneDX::BomRef']],
    default => sub { SBOM::CycloneDX::List->new }
);

sub TO_JSON {

    my $self = shift;

    my $json = {ref => $self->ref};

    $json->{dependsOn} = $self->depends_on if @{$self->depends_on};
    $json->{provides}  = $self->provides   if @{$self->provides};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Dependency - Dependency

=head1 SYNOPSIS

    SBOM::CycloneDX::Dependency->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Dependency> defines the direct dependencies of a
component, service, or the components provided/implemented by a given
component. Components or services that do not have their own dependencies
must be declared as empty elements within the graph. Components or services
that are not represented in the dependency graph may have unknown
dependencies. It is recommended that implementations assume this to be
opaque and not an indicator of an object being dependency-free. It is
recommended to leverage compositions to indicate unknown dependency graphs.

=head2 METHODS

L<SBOM::CycloneDX::Dependency> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Dependency->new( %PARAMS )

Properties:

=over

=item C<depends_on>, The bom-ref identifiers of the components or services
that are dependencies of this dependency object.

=item C<provides>, The bom-ref identifiers of the components or services
that define a given specification or standard, which are provided or
implemented by this dependency object.
For example, a cryptographic library which implements a cryptographic
algorithm. A component which implements another component does not imply
that the implementation is in use.

=item C<ref>, References a component or service by its bom-ref attribute

=back

=item $dependency->depends_on

=item $dependency->provides

=item $dependency->ref

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
