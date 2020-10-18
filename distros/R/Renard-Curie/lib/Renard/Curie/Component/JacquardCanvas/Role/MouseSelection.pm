use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::JacquardCanvas::Role::MouseSelection;
# ABSTRACT: Role for selecting text
$Renard::Curie::Component::JacquardCanvas::Role::MouseSelection::VERSION = '0.005';
use Role::Tiny;
use Intertangle::API::Gtk3::Helper;
use Glib qw(TRUE FALSE);
use Intertangle::Yarn::Types qw(Point Size);

after set_data => sub {
	my ($self, %data) = @_;

	$self->{selection}{state} = 0;
	$self->signal_connect( 'text-selected' => \&cb_on_text_selected );
};

sub mark_selection_start {
	my ($self, $event_point) = @_;

	my $pointer_data = $self->_get_data_for_pointer($event_point);
	my $text_data = $self->_get_text_data_for_pointer( $pointer_data );
	$self->{selection}{start} = { pointer => $pointer_data, text => $text_data };
	$self->{selection}{end} = $self->{selection}{start};
}

sub mark_selection_end {
	my ($self, $event_point) = @_;

	my $pointer_data = $self->_get_data_for_pointer($event_point);
	my $text_data = $self->_get_text_data_for_pointer( $pointer_data );
	$self->{selection}{end} = { pointer => $pointer_data, text => $text_data };
	$self->queue_draw;
}

sub clear_selection {
	my ($self) = @_;
	$self->{selection}{state} = 0;
}

after cb_on_motion_notify_button1 => sub {
	my ($widget, $event, $self) = @_;

	if( $event->state & 'button1-mask' ) {
		#say "Continuing selection";
		my $event_point = Point->coerce([ $event->x, $event->y ]);
		$self->mark_selection_end($event_point);
		$self->{selection}{state} = 1;
	}

	return TRUE;
};

after cb_on_button_press_event => sub {
	my ($widget, $event, $self) = @_;

	if( $event->button == Gtk3::Gdk::BUTTON_PRIMARY ) {
		#say "Start selection";
		my $event_point = Point->coerce([ $event->x, $event->y ]);
		$self->mark_selection_start($event_point);
		$self->{selection}{state} = 1;
	}

	return TRUE;
};

after cb_on_button_release_event => sub {
	my ($widget, $event, $self) = @_;

	if( $event->state & 'button1-mask' ) {
		#say "End selection";
		my $event_point = Point->coerce([ $event->x, $event->y ]);
		if( $self->{selection}{state} == 2 ) {
			$self->clear_selection;
		} else {
			$self->mark_selection_end($event_point);
			$self->{selection}{state} = 2;
			$self->signal_emit( 'text-selected' , {
				start => $self->{selection}{start},
				end => $self->{selection}{end},
			});
		}
	}

	return TRUE;
};

sub cb_on_text_selected {
	my ($self, $selections) = @_;

	if( my $text =  $self->_get_text_for_selection($selections) ) {
		Gtk3::Clipboard::get(Gtk3::Gdk::Atom::intern ('PRIMARY', Glib::FALSE))
			->set_text($text);
	}
}

sub _get_text_for_selection {
	my ($self, $selections) = @_;

	my $text;

	my $start_pages = $selections->{start}{pointer}{pages};
	my $end_pages = $selections->{end}{pointer}{pages};
	if( @$start_pages && @$end_pages ) {
		my @sorted = sort {$a <=> $b} ( $start_pages->[0] , $end_pages->[0] );
		my @pgs = ( $sorted[0] .. $sorted[1] );
		my @bboxes;
		for my $page_number (@pgs) {
			my ($page, $view) = $self->_get_page_view_for_page_number($page_number);
			next unless $view;

			my @extents = $page->get_extents_from_selection(
				$selections->{start},
				$selections->{end}
			);

			if( @extents ) {
				@extents = sort {$a <=> $b} @extents;
				$text .=  $page->_textual_page->substr( $extents[0], $extents[1]-$extents[0] )->str;
			}
		}
	}

	$text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::JacquardCanvas::Role::MouseSelection - Role for selecting text

=head1 VERSION

version 0.005

=head1 METHODS

=head2 mark_selection_start

Mark start of selection.

=head2 mark_selection_end

Mark end of selection.

=head2 clear_selection

Clear selection data.

=head1 CALLBACKS

=head2 cb_on_text_selected

Callback for C<text-selected> signal.

Currently sets the primary clipboard to the text of the selection.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
