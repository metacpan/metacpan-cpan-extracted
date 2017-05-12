package Padre::Plugin::Ecliptic;
BEGIN {
  $Padre::Plugin::Ecliptic::VERSION = '0.23';
}

# ABSTRACT: Padre plugin that provides Eclipse-like useful features

use strict;
use warnings;

# module imports
use Padre::Wx ();

# is a subclass of Padre::Plugin
use base 'Padre::Plugin';

#
# Returns the plugin name to Padre
#
sub plugin_name {
	return Wx::gettext("Ecliptic");
}

#
# This plugin is compatible with the following Padre plugin interfaces version
#
sub padre_interfaces {
	return 'Padre::Plugin' => 0.47;
}

#
# Returns the current share directory location
#
sub _sharedir {
	return Padre::Util::share('Ecliptic');
}

#
# plugin's real icon...
#
sub logo_icon {
	my ($self) = @_;

	my $icon = Wx::Icon->new;
	$icon->CopyFromBitmap( $self->plugin_icon );

	return $icon;
}

#
# plugin's bitmap not icon
#
sub plugin_icon {
	my $self = shift;

	# find resource path
	my $iconpath = File::Spec->catfile( $self->_sharedir, 'icons', 'ecliptic.png' );

	# create and return icon
	return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );
}

#
# Called when the plugin is enabled
#
sub plugin_enable {
	my $self = shift;

	# Read the plugin configuration, and create it if it is not there
	my $config = $self->config_read;
	if ( not $config ) {

		# no configuration, let us write some defaults
		$config = {};
	}
	if ( not defined $config->{quick_menu_history} ) {
		$config->{quick_menu_history} = '';
	}

	# and write the plugin's configuration
	$self->config_write($config);
}

#
# called when Padre needs the plugin's menu
#
sub menu_plugins {
	my $self        = shift;
	my $main_window = shift;

	# Create a menu
	$self->{menu} = Wx::Menu->new;

	# Shows the "Quick Assist" dialog
	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, Wx::gettext("Quick Assist\tCtrl-Shift-L"), ),
		sub { $self->_show_quick_assist_dialog(); },
	);

	# Shows the "Quick Outline Access" dialog
	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, Wx::gettext("Quick Outline Access\tCtrl-4"), ),
		sub { $self->_show_quick_outline_access_dialog(); },
	);

	# Shows the "Quick Module Access" dialog
	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, Wx::gettext("Quick Module Access\tCtrl-5"), ),
		sub { $self->_show_quick_module_access_dialog(); },
	);

	#---------
	$self->{menu}->AppendSeparator;

	# the famous about menu item...
	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, Wx::gettext("About"), ),
		sub { $self->_show_about },
	);

	# Return our plugin with its label
	return ( $self->plugin_name => $self->{menu} );
}

#
# Shows the nice about dialog
#
sub _show_about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Ecliptic");
	$about->SetDescription( Wx::gettext("Provides Eclipse-like useful features to Padre.\n") );
	$about->SetVersion($Padre::Plugin::Ecliptic::VERSION);
	Wx::AboutBox($about);

	return;
}

#
# Opens the "Quick Assist" dialog
#
sub _show_quick_assist_dialog {
	my $self = shift;

	#Create and show the dialog
	require Padre::Plugin::Ecliptic::QuickAssistDialog;
	my $dialog = Padre::Plugin::Ecliptic::QuickAssistDialog->new($self);
	$dialog->ShowModal();

	return;
}

#
# Opens the "Quick Outline Access" dialog
#
sub _show_quick_outline_access_dialog {
	my $self = shift;

	#Create and show the dialog
	require Padre::Plugin::Ecliptic::QuickOutlineAccessDialog;
	my $dialog = Padre::Plugin::Ecliptic::QuickOutlineAccessDialog->new($self);
	$dialog->ShowModal();

	return;
}

#
# Opens the "Quick Module Access" dialog
#
sub _show_quick_module_access_dialog {
	my $self = shift;

	#Create and show the dialog
	require Padre::Plugin::Ecliptic::QuickModuleAccessDialog;
	my $dialog = Padre::Plugin::Ecliptic::QuickModuleAccessDialog->new($self);
	$dialog->ShowModal();

	return;
}

1;



=pod

=head1 NAME

Padre::Plugin::Ecliptic - Padre plugin that provides Eclipse-like useful features

=head1 VERSION

version 0.23

=head1 SYNOPSIS

	1. After installation, run Padre.
	2. Make sure that it is enabled from 'Plugins\Plugin Manager".
	3. Once enabled, there should be a menu option called Plugins/Ecliptic.

=head1 DESCRIPTION

Once you enable this Plugin under Padre, you'll get a brand new menu with the
following options:

=head2 Quick Assist (Shortcut: Ctrl + Shift + L)

This opens a dialog with a list of current Padre actions/shortcuts. When
you hit the OK button, the selected Padre action will be performed.

=head2 Quick Outline Access (Shortcut: Ctrl + 4)

This opens a dialog where you can search for outline tree. When you hit the OK
button, the outline element in the outline tree will be selected.

=head2 Quick Module Access (Shortcut: Ctrl + 5)

This opens a dialog where you can search for a CPAN module. When you hit the OK
button, the selected module will be displayed in Padre's POD browser.

=head2 About

Shows a classic about dialog with this module's name and version.

=head1 Why the name Ecliptic?

I wanted a simple plugin name for including Eclipse-related killer features into
Padre. So i came up with Ecliptic and it turned out to be the orbit which the
Sun takes. And i love it!

=head1 AUTHOR

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ahmad M. Zawawi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

