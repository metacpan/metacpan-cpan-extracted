use Renard::Incunabula::Common::Setup;
package Renard::Curie::ViewModel::ViewManager;
# ABSTRACT: Manages the currently open views
$Renard::Curie::ViewModel::ViewManager::VERSION = '0.005';
use Moo;
use Renard::Incunabula::Common::Types qw(InstanceOf Path FileUri PositiveInt PositiveOrZeroInt);
use Renard::Incunabula::Document::Types qw(DocumentModel ZoomLevel);
use Renard::Block::Format::PDF::Document;

use Glib::Object::Subclass
	'Glib::Object',
	signals => {
		'document-changed' => {
			param_types => [
				'Glib::Scalar', # DocumentModel
			]
		},
		'update-view' => {
			param_types => [
				'Glib::Scalar', # View
			]
		},
	},
	;


with qw(
	Renard::Curie::ViewModel::ViewManager::Role::Document

	Renard::Curie::ViewModel::ViewManager::Role::ViewOptions
	Renard::Curie::ViewModel::ViewManager::Role::GridView
	Renard::Curie::ViewModel::ViewManager::Role::Zoom

	Renard::Curie::ViewModel::ViewManager::Role::TTS
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::ViewModel::ViewManager - Manages the currently open views

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Glib::Object::Subclass>

=item * L<Moo::Object>

=item * L<Glib::Object>

=back

=head1 CONSUMES

=over 4

=item * L<Renard::Curie::ViewModel::ViewManager::Role::Document>

=item * L<Renard::Curie::ViewModel::ViewManager::Role::GridView>

=item * L<Renard::Curie::ViewModel::ViewManager::Role::TTS>

=item * L<Renard::Curie::ViewModel::ViewManager::Role::ViewOptions>

=item * L<Renard::Curie::ViewModel::ViewManager::Role::Zoom>

=back

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
