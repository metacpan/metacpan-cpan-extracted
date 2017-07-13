use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::View::Role::Zoomable;
# ABSTRACT: Role for view models that support zooming
$Renard::Curie::Model::View::Role::Zoomable::VERSION = '0.003';
use Moo::Role;
use Renard::Incunabula::Common::Types qw(ZoomLevel);

has zoom_level => (
	is => 'rw',
	isa => ZoomLevel,
	default => 1.0,
	trigger => 1 # _trigger_zoom_level
	);

requires '_trigger_zoom_level';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::View::Role::Zoomable - Role for view models that support zooming

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 zoom_level

A L<ZoomLevel|Renard::Incunabula::Common::Types/ZoomLevel> for the current zoom level for
the document.

=begin comment

=method _trigger_zoom_level

  method _trigger_zoom_level($new_zoom_level)

Called whenever the L</zoom_level> is changed. This tells the component to
redraw the current page at the new zoom level.

=end comment

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
