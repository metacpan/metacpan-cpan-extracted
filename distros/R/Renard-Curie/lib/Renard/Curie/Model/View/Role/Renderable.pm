use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::View::Role::Renderable;
# ABSTRACT: Role for rendering a view model
$Renard::Curie::Model::View::Role::Renderable::VERSION = '0.003';
use Moo::Role;
use Renard::Incunabula::Common::Types qw(InstanceOf SizeRequest);

method draw_page(
	(InstanceOf['Gtk3::DrawingArea']) $widget,
	(InstanceOf['Cairo::Context']) $cr
) {
	# uncoverable subroutine
	... # uncoverable statement
}

method get_size_request() :ReturnType( list => SizeRequest) {
	# uncoverable subroutine
	... # uncoverable statement
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::View::Role::Renderable - Role for rendering a view model

=head1 VERSION

version 0.003

=head1 METHODS

=head2 draw_page

Draws the pages for the current view model to a C<Gtk3::DrawingArea>.

=head2 get_size_request

Determines the size request for the current view.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
