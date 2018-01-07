use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::AccelMap;
# ABSTRACT: Set up the accelerator map (global keybindings)
$Renard::Curie::Component::AccelMap::VERSION = '0.004';
use Moo;
use Renard::Incunabula::Frontend::Gtk3::Helper;

method BUILD(@) {
	Gtk3::AccelMap::add_entry(
		'<Curie-Main>/File/Open',
		Gtk3::Gdk::KEY_O(),
		'control-mask'
	);

	Gtk3::AccelMap::add_entry(
		'<Curie-Main>/File/Quit',
		Gtk3::Gdk::KEY_Q(),
		'control-mask'
	);

	Gtk3::AccelMap::add_entry(
		'<Curie-Main>/View/Sidebar',
		Gtk3::Gdk::KEY_F9(),
		'release-mask'
	);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::AccelMap - Set up the accelerator map (global keybindings)

=head1 VERSION

version 0.004

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 METHODS

=head2 BUILD

Constructor that sets up the keybindings for the default accelerator map.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
