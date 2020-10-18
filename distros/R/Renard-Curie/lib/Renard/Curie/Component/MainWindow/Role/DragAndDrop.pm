use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::MainWindow::Role::DragAndDrop;
# ABSTRACT: Role for drag-and-drop
$Renard::Curie::Component::MainWindow::Role::DragAndDrop::VERSION = '0.005';
use Moo::Role;
use MooX::ShortHas;

use URI::file;

lazy DND_TARGET_URI_LIST => sub { 0 };
lazy DND_TARGET_TEXT     => sub { 1 };

requires 'content_box';

after BUILD => method() {
	$self->setup_dnd;
};

method setup_dnd() {
	$self->content_box->drag_dest_set('all', [], 'copy');
	my $target_list = Gtk3::TargetList->new([
		Gtk3::TargetEntry->new( 'text/uri-list', 0, $self->DND_TARGET_URI_LIST ),
		Gtk3::TargetEntry->new( 'text/plain'   , 0, $self->DND_TARGET_TEXT     )
	]);
	$self->content_box->drag_dest_set_target_list($target_list);

	$self->content_box->signal_connect('drag-data-received' =>
		\&on_drag_data_received_cb, $self );
}

callback on_drag_data_received_cb( $widget, $context, $x, $y, $data, $info, $time, $self ) {
	my $pdf_filename_text;

	if( $info == $self->DND_TARGET_URI_LIST ) {
		my @uris = @{ $data->get_uris };
		$pdf_filename_text = $uris[0];
	} elsif( $info == $self->DND_TARGET_TEXT ) {
		my $text = $data->get_text;
		if( $text =~ /^file:/ ) {
			$pdf_filename_text = $text;
		} else {
			warn "Do not know what to do with text drag-and-drop data: $text";
		}
	}

	if( defined $pdf_filename_text ) {
		$self->view_manager->open_document_as_file_uri(
			URI->new($pdf_filename_text, 'file')
		);
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::MainWindow::Role::DragAndDrop - Role for drag-and-drop

=head1 VERSION

version 0.005

=head1 METHODS

=head2 setup_dnd

  method setup_dnd()

Setup drag and drop.

=head1 CALLBACKS

=head2 on_drag_data_received_cb

  on_drag_data_received_cb

Whenever the drag and drop data is received by the application.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
