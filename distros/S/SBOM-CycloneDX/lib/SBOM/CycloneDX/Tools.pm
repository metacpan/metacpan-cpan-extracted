package SBOM::CycloneDX::Tools;

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

    $json->{components} = $self->components if @{$self->components};
    $json->{services}   = $self->services   if @{$self->services};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Tools - [Deprecated] The tool(s) used in the creation, enrichment,
and validation of the BOM

=head1 SYNOPSIS

    $tools = SBOM::CycloneDX::Tools->new;

    $tools->components->add($component);

=head1 DESCRIPTION

L<SBOM::CycloneDX::Tools> is a "deprecated" module for generate the tool(s) used
in the creation, enrichment, and validation of the BOM.

=head2 METHODS

L<SBOM::CycloneDX::Tools> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Tools->new( %PARAMS )

Create a new L<SBOM::CycloneDX::Tools> object.

Parameters:

=over

=item * C<components>, An ARRAY of software and hardware components used as tools.
See L<SBOM::CycloneDX::Component>.

=item * C<services>, An ARRAY of services used as tools. This may include microservices,
function-as-a-service, and other types of network or intra-process services.
See L<SBOM::CycloneDX::Service>.

=back

=item $tools->components

An ARRAY of software and hardware components used as tools.
See L<SBOM::CycloneDX::Component>

=item $tools->services

An ARRAY of services used as tools. This may include microservices,
function-as-a-service, and other types of network or intra-process services.
See L<SBOM::CycloneDX::Service>.

=item $tools->TO_JSON

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
