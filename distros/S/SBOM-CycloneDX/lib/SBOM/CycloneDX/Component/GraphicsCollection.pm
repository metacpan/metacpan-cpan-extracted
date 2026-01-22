package SBOM::CycloneDX::Component::GraphicsCollection;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has description => (is => 'rw', isa => Str);

has collection => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Component::Graphic']],
    default => sub { SBOM::CycloneDX::List->new }
);


sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{description} = $self->description if $self->description;
    $json->{collection}  = $self->collection  if @{$self->collection};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Component::GraphicsCollection - Graphics Collection

=head1 SYNOPSIS

    SBOM::CycloneDX::Component::GraphicsCollection->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Component::GraphicsCollection> provides a collection of graphics
that represent various measurements.

=head2 METHODS

L<SBOM::CycloneDX::Component::GraphicsCollection> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Component::GraphicsCollection->new( %PARAMS )

Properties:

=over

=item * C<collection>, A collection of graphics.

=item * C<description>, A description of this collection of graphics.

=back

=item $graphics_collection->collection

=item $graphics_collection->description

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
