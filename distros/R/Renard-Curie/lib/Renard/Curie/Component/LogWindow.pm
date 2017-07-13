use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::LogWindow;
# ABSTRACT: Component that collects log messages
$Renard::Curie::Component::LogWindow::VERSION = '0.003';
use Moo;
use Renard::Incunabula::Frontend::Gtk3::Helper;
use MooX::HandlesVia;
use Glib 'TRUE', 'FALSE';
use Renard::Incunabula::Common::Types qw(ArrayRef HashRef Str);

has log_messages => (
	is => 'rw',
	handles_via => 'Array',
	isa => ArrayRef[HashRef],
	clearer => 1,
	handles => {
		add_log => 'push',
	},
	default => sub { [] },
);

method BUILD(@) {
	my $log_textview = $self->builder->get_object('log-text');
	if( $log_textview->can('set_monospace') ) {
		$log_textview->set_monospace(TRUE);
	} else {
		warn('Gtk3::TextView monospace property not available for Gtk+ < v3.16.');
	}
	$self->builder->get_object('log-window')
		->signal_connect(
			'delete-event'
			# Gtk3::Widget::hide_on_delete
			=> sub { shift->hide_on_delete } );
	$self->builder->get_object('button-clear')
		->signal_connect(
			clicked =>
			\&on_clicked_button_clear_cb, $self );
}

method show_log_window() {
	$self->builder->get_object('log-window')->show_all;
}

method log( (Str) :$category, (Str) :$level, (Str) :$message ) {
	$self->add_log( {
		category => $category,
		level => $level,
		message => $message } );

	my $buffer = $self->builder->get_object('log-text')->get_buffer;
	$buffer->insert( $buffer->get_end_iter,
		sprintf("[%s] {%s} %s\n", $level, $category, $message ) );

	$self->_scroll_log_textview_to_end;
}

method _scroll_log_textview_to_end() {
	my $text_view = $self->builder->get_object('log-text');
	my $buffer = $text_view->get_buffer;

	my $end_iter = $buffer->get_end_iter;
	my $insert_mark = $buffer->get_insert;

	# move the mark and selection to the end
	$buffer->place_cursor($end_iter);

	#  scroll the view to the end
	$text_view->scroll_to_mark( $insert_mark, 0.0, TRUE, 0.0, 1.0);
}

callback on_clicked_button_clear_cb( $event, $self ) {
	$self->log_messages([]);
	my $buffer = $self->builder->get_object('log-text')->get_buffer;
	$buffer->set_text("", 0);
}

with qw(
	Renard::Incunabula::Frontend::Gtk3::Component::Role::FromBuilder
	Renard::Incunabula::Frontend::Gtk3::Component::Role::UIFileFromPackageName
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::LogWindow - Component that collects log messages

=head1 VERSION

version 0.003

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 CONSUMES

=over 4

=item * L<Renard::Incunabula::Frontend::Gtk3::Component::Role::FromBuilder>

=item * L<Renard::Incunabula::Frontend::Gtk3::Component::Role::UIFileFromPackageName>

=back

=head1 ATTRIBUTES

=head2 log_messages

An C<ArrayRef[HashRef]> of log messages where each item has the keys

=over 4

=item *

C<category>

=item *

C<level>

=item *

C<message>

=back

See the L</log> method for more details.

=head1 METHODS

=head2 BUILD

  method BUILD

Initialises the logging window.

=head2 show_log_window

  method show_log_window()

Displays the hidden logging window.

=head2 log

  method log( (Str) :$category, (Str) :$level, (Str) :$message )

Called by the L<Renard::Curie::Log::Any::Adapter::LogWindow> adapter to send
logging messages to this component.

=over 4

=item *

C<$category> is category for the log message (e.g, which package generated it).

=item *

C<$level> is the severity of the message (e.g., info, warning, debug).

=item *

C<$message> is the message itself.

=back

=head2 _scroll_log_textview_to_end

  method _scroll_log_textview_to_end()

Scrolls the text view of logging messages to the end so that the last message
is visible.

=head1 CALLBACKS

=head2 on_clicked_button_clear_cb

  callback on_clicked_button_clear_cb( $event, $self )

Callback for when the Clear button is clicked. This clears the log message text
view.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
