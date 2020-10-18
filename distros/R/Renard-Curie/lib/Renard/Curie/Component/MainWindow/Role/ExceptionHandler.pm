use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::MainWindow::Role::ExceptionHandler;
# ABSTRACT: A role for handling exceptions
$Renard::Curie::Component::MainWindow::Role::ExceptionHandler::VERSION = '0.005';
use Moo::Role;
use Gtk3;
use Glib 'TRUE', 'FALSE';

use constant EXCEPTION_DIALOG_LABEL_MAX_WIDTH_CHARS => 30;

has _exception_handler => (
	is => 'lazy', # _build__exception_handler
);

method _build__exception_handler() {
	Glib->install_exception_handler( my $cb = fun( $exception ) {
		if ( $exception->isa('Renard::Curie::Error::User::InvalidPageNumber') ) {
			$self->_show_exception_dialog_box(
				'Page number entered is invalid: entered "%s", should be between %s and %s.',
				[
					$exception->payload->{text},
					$exception->payload->{range}[0],
					$exception->payload->{range}[1],
				],
			);
		} else {
			$self->_show_exception_dialog_box( "$exception" );
		}

		return TRUE; # keep the handler
	});
};


method _show_exception_dialog_box( $message_fmt, $params = [] ) {
	my $flags = [ qw/modal destroy_with_parent/ ];
	my $dialog = Gtk3::Dialog->new(
		"Error",
		$self->window,
		$flags,
		"_Close", 'close',
	);

	my $hbox = Gtk3::Box->new( 'horizontal', 0 );

	# add image
	$hbox->add(
		Gtk3::Image->new_from_icon_name ("dialog-error", 'dialog')
	);

	# add label
	my $label = Gtk3::Label->new(
		sprintf($message_fmt, @$params)
	);
	$label->set_line_wrap(TRUE);
	$label->set_max_width_chars(EXCEPTION_DIALOG_LABEL_MAX_WIDTH_CHARS);
	$label->set_selectable(TRUE);
	$hbox->pack_end( $label, TRUE, FALSE, 0 );

	$dialog->get_content_area->pack_start( $hbox, TRUE, TRUE, 0 );

	$dialog->signal_connect( response => sub { $dialog->destroy } );

	$dialog->show_all;

	my $result = $dialog->run;
}

after setup_window => method() {
	$self->_exception_handler;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::MainWindow::Role::ExceptionHandler - A role for handling exceptions

=head1 VERSION

version 0.005

=head1 ATTRIBUTES

=head2 EXCEPTION_DIALOG_LABEL_MAX_WIDTH_CHARS

Constant with maximum width for exception dialog.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
