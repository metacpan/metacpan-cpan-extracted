use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::PageDrawingArea::Role::PageLabel;
# ABSTRACT: A role for the number of pages label
$Renard::Curie::Component::PageDrawingArea::Role::PageLabel::VERSION = '0.004';
use Moo::Role;

after BUILD => method(@) {
	$self->setup_number_of_pages_label;
};

method setup_number_of_pages_label() {
	$self->builder->get_object("number-of-pages-label")
		->set_text( $self->view->document->number_of_pages );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::PageDrawingArea::Role::PageLabel - A role for the number of pages label

=head1 VERSION

version 0.004

=head1 METHODS

=head2 setup_number_of_pages_label

  method setup_number_of_pages_label()

Sets up the label that shows the number of pages in the document.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
