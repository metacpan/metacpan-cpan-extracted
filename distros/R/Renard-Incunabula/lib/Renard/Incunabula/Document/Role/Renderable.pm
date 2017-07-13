use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Document::Role::Renderable;
# ABSTRACT: Role for documents that can render their pages
$Renard::Incunabula::Document::Role::Renderable::VERSION = '0.003';
use Moo::Role;

requires 'get_rendered_page';

# TODO implement the actual method signature here

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Document::Role::Renderable - Role for documents that can render their pages

=head1 VERSION

version 0.003

=head1 METHODS

=head2 get_rendered_page

  get_rendered_page( %opts )

Returns a C<Renard::Incunabula::Page::Role::CairoRenderable>.

The options for this function are:

=over 4

=item * C<<page_number => PageNumber $page_number>>:

The page number to retrieve.

Required. Value must be a C<PageNumber> which must be between the
C<first_page_number> and C<last_page_number>.

=item * C<<zoom_level => ZoomLevel $zoom_level>>:

The amount of zoom to use in order to control the dimensions of the
rendered PDF page. This is C<1.0> by default.

Optional. Value must be a C<ZoomLevel>.

=back

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
