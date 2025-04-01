package SBOM::CycloneDX::Component::Graphic;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has name  => (is => 'rw', isa => Str);
has image => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Attachment']);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{name}  = $self->name  if $self->name;
    $json->{image} = $self->image if $self->image;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Component::Graphic - Graphic

=head1 SYNOPSIS

    SBOM::CycloneDX::Component::Graphic->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Component::Graphic> provides the graphic object.

=head2 METHODS

L<SBOM::CycloneDX::Component::Graphic> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Component::Graphic->new( %PARAMS )

Properties:

=over

=item C<image>, The graphic (vector or raster). Base64 encoding must be
specified for binary images.

=item C<name>, The name of the graphic.

=back

=item $graphic->image

=item $graphic->name

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
