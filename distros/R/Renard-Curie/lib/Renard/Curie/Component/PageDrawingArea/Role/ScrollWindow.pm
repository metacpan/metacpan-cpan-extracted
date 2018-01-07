use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::PageDrawingArea::Role::ScrollWindow;
# ABSTRACT: A role with helpers for scrolling the page drawing area viewport
$Renard::Curie::Component::PageDrawingArea::Role::ScrollWindow::VERSION = '0.004';
use Moo::Role;
use Gtk3;
use Renard::Incunabula::Common::Types qw(InstanceOf);

method increment_scroll( (InstanceOf['Gtk3::Adjustment']) $current ) {
	my $adjustment = $current->get_value + $current->get_step_increment;
	$current->set_value($adjustment);
}

method decrement_scroll( (InstanceOf['Gtk3::Adjustment']) $current ) {
	my $adjustment = $current->get_value - $current->get_step_increment;
	$current->set_value($adjustment);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::PageDrawingArea::Role::ScrollWindow - A role with helpers for scrolling the page drawing area viewport

=head1 VERSION

version 0.004

=head1 METHODS

=head2 increment_scroll

  method increment_scroll( (InstanceOf['Gtk3::Adjustment']) $current )

Helper method that scrolls down by the scrollbar's step increment.

=head2 decrement_scroll

  method decrement_scroll( (InstanceOf['Gtk3::Adjustment']) $current )

Helper method that scrolls up by the scrollbar's step increment.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
