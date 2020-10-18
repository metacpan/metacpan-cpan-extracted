use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::MainWindow::Role::MenuBar;
# ABSTRACT: Role for menu bar
$Renard::Curie::Component::MainWindow::Role::MenuBar::VERSION = '0.005';
use Moo::Role;

use Renard::Curie::Component::MenuBar;
use Renard::Curie::Component::FileChooser;
use Renard::Incunabula::Common::Types qw(InstanceOf);
use Renard::Incunabula::Document::Types qw(DocumentModel);
use Renard::Curie::Component::DocumentPropertiesWindow;

use Glib 'TRUE', 'FALSE';

has menu_bar => (
	is => 'ro',
	required => 1,
	isa => InstanceOf['Renard::Curie::Component::MenuBar'],
);


before setup_window => method() {
	$self->builder->get_object('application-vbox')
		->pack_start( $self->menu_bar, FALSE, TRUE, 0 );
};

after open_document => method( (DocumentModel) $doc ) {
	if( $doc->can('filename_uri') ) {
		my $rm_added = $self->menu_bar->recent_manager->add_item( $doc->filename_uri );
	}
};

callback on_open_file_dialog_cb( $event, $self ) {
	my $file_chooser = Renard::Curie::Component::FileChooser->new( main_window => $self );
	my $dialog = $file_chooser->get_open_file_dialog_with_filters;

	my $result = $dialog->run;

	if ( $result eq 'accept' ) {
		my $filename = $dialog->get_filename;
		$dialog->destroy;
		$self->view_manager->open_pdf_document($filename);
	} else {
		$dialog->destroy;
	}
}

callback on_document_properties_dialog_cb( $event, $self ) {
	Renard::Curie::Component::DocumentPropertiesWindow->new(
		document => $self->view_manager->current_document
	)->show_all;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::MainWindow::Role::MenuBar - Role for menu bar

=head1 VERSION

version 0.005

=head1 ATTRIBUTES

=head2 menu_bar

A L<Renard::Curie::Component::MenuBar> for the application's menu-bar.

=head1 CALLBACKS

=head2 on_open_file_dialog_cb

  callback on_open_file_dialog_cb( $event, $self )

Callback that opens a L<Renard::Curie::Component::FileChooser> component.

=head2 on_document_properties_dialog_cb

  callback on_document_properties_dialog_cb( $event, $self )

Callback that opens a L<Renard::Curie::Component::DocumentPropertiesWindow>
component for the current document.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
