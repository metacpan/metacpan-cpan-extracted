use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Page::Role::CairoRenderable;
# ABSTRACT: Role for pages that represented by a Cairo image surface
$Renard::Incunabula::Page::Role::CairoRenderable::VERSION = '0.003';
use Moo::Role;
use Function::Parameters;
use Renard::Incunabula::Common::Types qw(PositiveOrZeroInt);
use Function::Parameters;

requires 'cairo_image_surface';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Page::Role::CairoRenderable - Role for pages that represented by a Cairo image surface

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 cairo_image_surface

The L<Cairo::ImageSurface> which consumers of this role will render.

Consumes of this role must implement this.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
