use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::PageDrawingArea::Role::PageEntry;
# ABSTRACT: A role for the text entry box for the page number
$Renard::Curie::Component::PageDrawingArea::Role::PageEntry::VERSION = '0.005';
use Moo::Role;

after BUILD => method(@) {
	$self->setup_text_entry_events;
};

method setup_text_entry_events() {
	$self->builder->get_object('page-number-entry')->signal_connect(
		activate => \&on_activate_page_number_entry_cb, $self );
}

callback on_activate_page_number_entry_cb( $entry, $self ) {
	my $text = $entry->get_text;
	$entry->set_text("");
	if( $self->view->document->is_valid_page_number($text) ) {
		$self->view->set_page_number_with_scroll( $text );
	} else {
		Renard::Curie::Error::User::InvalidPageNumber->throw({
			payload => {
				text => $text,
				range => [
					$self->view->document->first_page_number,
					$self->view->document->last_page_number
				],
			}
		});
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::PageDrawingArea::Role::PageEntry - A role for the text entry box for the page number

=head1 VERSION

version 0.005

=head1 METHODS

=head2 setup_text_entry_events

  method setup_text_entry_events()

Sets up the signals for the text entry box so the user can enter in page
numbers.

=head1 CALLBACKS

=head2 on_activate_page_number_entry_cb

  callback on_activate_page_number_entry_cb( $entry, $self )

Callback that is called when text has been entered into the page number entry.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
