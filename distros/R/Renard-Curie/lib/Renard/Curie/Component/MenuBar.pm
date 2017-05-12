use Renard::Curie::Setup;
package Renard::Curie::Component::MenuBar;
# ABSTRACT: Component that provides a menu bar for the application
$Renard::Curie::Component::MenuBar::VERSION = '0.001';
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

method BUILD {
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

	# Help menu
	$self->builder->get_object('menu-item-help-logwin')
		->signal_connect( activate =>
			\&on_menu_help_logwin_activate_cb, $self );

	# add as child for this Gtk3::Bin
	$self->add(
		$self->builder->get_object('menubar')
	);
}

method _build_recent_manager :ReturnType(InstanceOf['Gtk3::RecentManager']) {
	Gtk3::RecentManager::get_default;
}

method _build_recent_chooser :ReturnType(InstanceOf['Gtk3::RecentChooserMenu']) {
	my $recent_chooser = Gtk3::RecentChooserMenu->new_for_manager( $self->recent_manager );
}


# Callbacks {{{
fun on_menu_file_open_activate_cb($event, $self) {
	Renard::Curie::Helper->callback( $self->app, on_open_file_dialog_cb => $event );
}

fun on_menu_file_quit_activate_cb($event, $self) {
	Renard::Curie::Helper->callback( $self->app, on_application_quit_cb => $event );
}

fun on_menu_file_recentfiles_item_activated_cb( (InstanceOf['Gtk3::RecentChooserMenu']) $recent_chooser, $self ) {
	my $selected_item = $recent_chooser->get_current_item;
	my $uri = $selected_item->get_uri;
	my $file = URI->new( $uri )->file;
	$self->app->open_pdf_document( $file );
}

fun on_menu_help_logwin_activate_cb($event, $self) {
	$self->app->log_window->show_log_window;
}

fun on_menu_view_sidebar_cb($event_menu_item, $self) {
	$self->app->outline->reveal( $event_menu_item->get_active );
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

version 0.001

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

=head1 METHODS

=head2 BUILD

  method BUILD

Initialises the menu bar signals.

=head1 CLASS METHODS

=head2 FOREIGNBUILDARGS

  classmethod FOREIGNBUILDARGS(@)

Builds the L<Gtk3::Bin> super-class.

=head1 CALLBACKS

=head2 on_menu_file_open_activate_cb

  fun on_menu_file_open_activate_cb($event, $self)

Callback for the C<< File -> Open >> menu item.

=head2 on_menu_file_quit_activate_cb

  fun on_menu_file_quit_activate_cb($event, $self)

Callback for the C<< File -> Quit >> menu item.

=head2 on_menu_file_recentfiles_item_activated_cb

  fun on_menu_file_recentfiles_item_activated_cb( (InstanceOf['Gtk3::RecentChooserMenu']) $recent_chooser, $self )

Callback for items under the C<< File -> Recent files >> sub-menu.

=head2 on_menu_help_logwin_activate_cb

  fun on_menu_help_logwin_activate_cb($event, $self)

Callback for C<< Help -> Message log >> menu item.

Displays the Message log window.

=head2 on_menu_view_sidebar_cb

Callback for the C<< View -> Sidebar >> menu item.

This toggles whether or not the outline sidebar is visible.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
