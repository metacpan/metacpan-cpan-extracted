use Renard::Curie::Setup;
package Renard::Curie::Component::MenuBar;
# ABSTRACT: Component that provides a menu bar for the application
$Renard::Curie::Component::MenuBar::VERSION = '0.002';
use Moo;
use URI;
use Glib::Object::Subclass 'Gtk3::Bin';
use Glib 'TRUE', 'FALSE';
use Function::Parameters;
use Renard::Curie::Types qw(InstanceOf);
use Renard::Curie::Helper;

has recent_manager => (
	is => 'lazy', # _build_recent_manager
	isa => InstanceOf['Gtk3::RecentManager'],
);

has recent_chooser => (
	is => 'lazy', # _build_recent_chooser
	isa => InstanceOf['Gtk3::RecentChooserMenu'],
);

classmethod FOREIGNBUILDARGS(@) {
	return ();
}

method BUILD(@) {
	# Accelerator group
	$self->app->window->add_accel_group(
		$self->builder->get_object('menu-accel-group')
	);

	# File menu
	$self->builder->get_object('menu-item-file-open')
		->signal_connect( activate =>
			\&on_menu_file_open_activate_cb, $self );
	$self->builder->get_object('menu-item-file-quit')
		->signal_connect( activate =>
			\&on_menu_file_quit_activate_cb, $self );

	$self->builder->get_object('menu-item-file-recentfiles')
		->set_submenu($self->recent_chooser);

	$self->recent_chooser->signal_connect( 'item-activated' =>
		\&on_menu_file_recentfiles_item_activated_cb, $self );


	# View menu
	#$self->builder->get_object('menu-item-view-pagemode-singlepage')
		#->set_active(TRUE);

	# Make sure that the menu-item-view-sidebar object matches
	# the outline's revealer state once the application starts.
	Glib::Timeout->add( 0, sub {
		$self->builder->get_object('menu-item-view-sidebar')
			->set_active($self->app->outline->get_reveal_child);
		return FALSE; # run only once
	});
	$self->builder->get_object('menu-item-view-sidebar')
		->signal_connect( toggled =>
			\&on_menu_view_sidebar_cb, $self );

	## View -> Zoom menu
	my @zoom_levels = (
		{ text => "50%",   zoom_level => 0.5 },
		{ text => "70%",   zoom_level => 0.7071067811 },
		{ text => "85%",   zoom_level => 0.8408964152 },
		{ text => "100%",  zoom_level => 1.0 },
		{ text => "125%",  zoom_level => 1.1892071149 },
		{ text => "150%",  zoom_level => 1.4142135623 },
		{ text => "175%",  zoom_level => 1.6817928304 },
		{ text => "200%",  zoom_level => 2.0 },
		{ text => "300%",  zoom_level => 2.8284271247 },
		{ text => "400%",  zoom_level => 4.0 },
		{ text => "800%",  zoom_level => 8.0 },
		{ text => "1600%", zoom_level => 16.0 },
		{ text => "3200%", zoom_level => 32.0 },
		{ text => "6400%", zoom_level => 64.0 }
	);
	my $zoom_submenu = $self->builder->get_object('menu-view-zoom');
	for my $zoom_menu_info (@zoom_levels) {
		my $menu_item = Gtk3::MenuItem->new_with_label( $zoom_menu_info->{text} );
		$zoom_submenu->add( $menu_item );
		$menu_item->signal_connect( activate =>
			\&on_menu_view_zoom_item_activate_cb, [ $self, $zoom_menu_info->{zoom_level} ] );
	}

	# Help menu
	$self->builder->get_object('menu-item-help-logwin')
		->signal_connect( activate =>
			\&on_menu_help_logwin_activate_cb, $self );

	# add as child for this Gtk3::Bin
	$self->add(
		$self->builder->get_object('menubar')
	);
}

method _build_recent_manager() :ReturnType(InstanceOf['Gtk3::RecentManager']) {
	Gtk3::RecentManager::get_default;
}

method _build_recent_chooser() :ReturnType(InstanceOf['Gtk3::RecentChooserMenu']) {
	my $recent_chooser = Gtk3::RecentChooserMenu->new_for_manager( $self->recent_manager );
}


# Callbacks {{{
callback on_menu_file_open_activate_cb($event, $self) {
	Renard::Curie::Helper->callback( $self->app, on_open_file_dialog_cb => $event );
}

callback on_menu_file_quit_activate_cb($event, $self) {
	Renard::Curie::Helper->callback( $self->app, on_application_quit_cb => $event );
}

callback on_menu_file_recentfiles_item_activated_cb( (InstanceOf['Gtk3::RecentChooserMenu']) $recent_chooser, $self ) {
	my $selected_item = $recent_chooser->get_current_item;
	my $uri = $selected_item->get_uri;
	my $file = URI->new( $uri )->file;
	$self->app->open_pdf_document( $file );
}

callback on_menu_help_logwin_activate_cb($event, $self) {
	$self->app->log_window->show_log_window;
}

callback on_menu_view_sidebar_cb($event_menu_item, $self) {
	$self->app->outline->reveal( $event_menu_item->get_active );
}

callback on_menu_view_zoom_item_activate_cb($event, $data) {
	my ($self, $zoom_level) = @$data;
	$self->app->page_document_component->zoom_level( $zoom_level );
}

# }}}


with qw(
	Renard::Curie::Component::Role::FromBuilder
	Renard::Curie::Component::Role::UIFileFromPackageName
	Renard::Curie::Component::Role::HasParentApp
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::MenuBar - Component that provides a menu bar for the application

=head1 VERSION

version 0.002

=head1 EXTENDS

=over 4

=item * L<Glib::Object::Subclass>

=item * L<Moo::Object>

=item * L<Gtk3::Bin>

=item * L<Glib::Object::_Unregistered::AtkImplementorIface>

=item * L<Gtk3::Buildable>

=back

=head1 CONSUMES

=over 4

=item * L<Renard::Curie::Component::Role::FromBuilder>

=item * L<Renard::Curie::Component::Role::HasParentApp>

=item * L<Renard::Curie::Component::Role::UIFileFromPackageName>

=back

=head1 ATTRIBUTES

=head2 recent_manager

A lazy attribute that holds the default instance of L<Gtk3::RecentManager>.

=head2 recent_chooser

Instance of L<Gtk3::RecentChooserMenu> which is placed under the C<<File ->
Recent files>> sub-menu.

=head1 CLASS METHODS

=head2 FOREIGNBUILDARGS

  classmethod FOREIGNBUILDARGS(@)

Builds the L<Gtk3::Bin> super-class.

=head1 METHODS

=head2 BUILD

  method BUILD

Initialises the menu bar signals.

=head1 CALLBACKS

=head2 on_menu_file_open_activate_cb

  callback on_menu_file_open_activate_cb($event, $self)

Callback for the C<< File -> Open >> menu item.

=head2 on_menu_file_quit_activate_cb

  callback on_menu_file_quit_activate_cb($event, $self)

Callback for the C<< File -> Quit >> menu item.

=head2 on_menu_file_recentfiles_item_activated_cb

  callback on_menu_file_recentfiles_item_activated_cb( (InstanceOf['Gtk3::RecentChooserMenu']) $recent_chooser, $self )

Callback for items under the C<< File -> Recent files >> sub-menu.

=head2 on_menu_help_logwin_activate_cb

  callback on_menu_help_logwin_activate_cb($event, $self)

Callback for C<< Help -> Message log >> menu item.

Displays the Message log window.

=head2 on_menu_view_sidebar_cb

Callback for the C<< View -> Sidebar >> menu item.

This toggles whether or not the outline sidebar is visible.

=head2 on_menu_view_zoom_item_activate_cb

Callback for zoom level menu items under the C<< View -> Zoom >> submenu.

  callback on_menu_view_zoom_item_activate_cb($event, $data)

where C<$data> is an C<ArrayRef> that contains C<< [ $self, $zoom_level ] >>.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
