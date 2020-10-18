use Renard::Incunabula::Common::Setup;
package Renard::Curie::ViewModel::ViewManager::Role::Zoom;
# ABSTRACT: A role for zoom
$Renard::Curie::ViewModel::ViewManager::Role::Zoom::VERSION = '0.005';
use Moo::Role;

use Renard::Incunabula::Document::Types qw(ZoomLevel);
use Renard::Curie::Model::ViewOptions::Zoom::Percentage;

method set_zoom_level( (ZoomLevel) $zoom_level ) {
	my $zoom_option = Renard::Curie::Model::ViewOptions::Zoom::Percentage->new(
		zoom_level => $zoom_level,
	);
	my $view_options = $self->view_options->cset(
		zoom_options => $zoom_option
	);
	$self->view_options( $view_options );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::ViewModel::ViewManager::Role::Zoom - A role for zoom

=head1 VERSION

version 0.005

=head1 METHODS

=head2 set_zoom_level

  method set_zoom_level( (ZoomLevel) $zoom_level )

Sets the L</current_view> to L<Renard::Curie::Model::View::Grid> with C<zoom_level>
of L<Renard::Curie::Model::ViewOptions::Zoom::Percentage> set to C<$zoom_level>.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
