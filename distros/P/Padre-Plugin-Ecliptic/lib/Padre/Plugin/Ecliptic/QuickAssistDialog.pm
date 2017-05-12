package Padre::Plugin::Ecliptic::QuickAssistDialog;
BEGIN {
  $Padre::Plugin::Ecliptic::QuickAssistDialog::VERSION = '0.23';
}

# ABSTRACT: Quick assist autocomplete dialog

use warnings;
use strict;

# module imports
use Padre::Wx ();

# is a subclass of Wx::Dialog
use base 'Wx::Dialog';

# accessors
use Class::XSAccessor accessors => {
	_plugin        => '_plugin',        # Plugin object
	_sizer         => '_sizer',         # window sizer
	_bindings_list => '_bindings_list', # key bindings list
};

# -- constructor
sub new {
	my ( $class, $plugin, %opt ) = @_;

	# create object
	my $self = $class->SUPER::new(
		$plugin->main,
		-1,
		Wx::gettext('Quick Assist'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE | Wx::wxTAB_TRAVERSAL,
	);

	$self->SetIcon(Wx::GetWxPerlIcon);
	$self->_plugin($plugin);

	# create dialog
	$self->_create;

	# Dialog's icon as is the same as plugin's
	$self->SetIcon( $plugin->logo_icon );

	return $self;
}


# -- event handler

#
# handler called when the ok button has been clicked.
#
sub _on_ok_button_clicked {
	my ($self) = @_;

	my $main = $self->_plugin->main;

	#Open the selected menu item if the user pressed OK
	my $selection = $self->_bindings_list->GetFirstSelected;
	if ( $selection != -1 ) {
		my $selected_menu_item = $self->_bindings_list->GetItem( $selection, 0 );
		if ($selected_menu_item) {
			my $event = Wx::CommandEvent->new( Wx::wxEVT_COMMAND_MENU_SELECTED,
				$selected_menu_item->GetId
			);
			$main->GetEventHandler->ProcessEvent($event);
		}
	}

	$self->Destroy;
}


# -- private methods

#
# create the dialog itself.
#
sub _create {
	my ($self) = @_;

	# create sizer that will host all controls
	my $sizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$self->_sizer($sizer);

	# create the controls
	$self->_create_controls;
	$self->_create_buttons;

	# wrap everything in a vbox to add some padding
	$self->SetSizerAndFit($sizer);
	$sizer->SetSizeHints($self);

	# The dialog should be centered (more standard)
	$self->Centre;

	# focus on the search text box
	$self->_bindings_list->SetFocus;
}

#
# create the buttons pane.
#
sub _create_buttons {
	my ($self) = @_;
	my $sizer = $self->_sizer;

	my $butsizer = $self->CreateStdDialogButtonSizer( Wx::wxOK | Wx::wxCANCEL );
	$sizer->Add( $butsizer, 0, Wx::wxALL | Wx::wxEXPAND | Wx::wxALIGN_CENTER, 5 );
	Wx::Event::EVT_BUTTON( $self, Wx::wxID_OK, \&_on_ok_button_clicked );
}

#
# create controls in the dialog
#
sub _create_controls {
	my ($self) = @_;

	$self->_create_key_bindings_list();

	$self->_sizer->AddSpacer(10);
	$self->_sizer->Add( $self->_bindings_list, 0, Wx::wxALL | Wx::wxEXPAND, 2 );

	$self->_setup_events;

	return;
}

#
# Adds various events
#
sub _setup_events {
	my $self = shift;

	Wx::Event::EVT_LIST_ITEM_ACTIVATED(
		$self,
		$self->_bindings_list,
		sub {

			$self->_on_ok_button_clicked();
			$self->EndModal(0);

			return;
		}
	);

}

#
# Update matches list box from matched files list
#
sub _create_key_bindings_list {
	my $self = shift;

	$self->_bindings_list(
		Wx::ListView->new(
			$self,
			-1,
			Wx::wxDefaultPosition,
			[ 305, 300 ],
			Wx::wxLC_REPORT | Wx::wxLC_NO_HEADER | Wx::wxLC_SINGLE_SEL
		)
	);


	$self->_bindings_list->InsertColumn( 0, '' );
	$self->_bindings_list->InsertColumn( 1, '' );

	$self->_bindings_list->SetColumnWidth( 0, 180 );
	$self->_bindings_list->SetColumnWidth( 1, 100 );

	$self->_bindings_list->SetBackgroundColour( Wx::Colour->new( 255, 255, 225 ) );

	my $main     = $self->_plugin->main;
	my $menu_bar = $main->menu->wx;

	#walk the menu items tree
	sub walk_menu {
		my $menu = shift;

		my @menu_items = ();
		foreach my $menu_item ( $menu->GetMenuItems ) {
			my $sub_menu = $menu_item->GetSubMenu;
			if ($sub_menu) {
				push @menu_items, walk_menu($sub_menu);
			} elsif ( not $menu_item->IsSeparator ) {
				push @menu_items, $menu_item;
			}
		}

		return @menu_items;
	}

	my $menu_count = $menu_bar->GetMenuCount;
	my @menu_items = ();
	foreach my $menu_pos ( 0 .. $menu_count - 1 ) {
		my $main_menu       = $menu_bar->GetMenu($menu_pos);
		my $main_menu_label = $menu_bar->GetMenuLabel($menu_pos);
		push @menu_items, walk_menu($main_menu);
	}

	@menu_items = reverse sort { $a->GetLabel cmp $b->GetLabel } @menu_items;

	foreach my $menu_item (@menu_items) {
		my $menu_item_label    = $menu_item->GetLabel;
		my $menu_item_shortcut = $menu_item->GetText;

		if ( $menu_item_shortcut =~ /\t/ ) {
			$menu_item_shortcut =~ s/^.+?\t//;

			my $item;
			$item = Wx::ListItem->new();
			$item->SetText($menu_item_label);
			$item->SetData($menu_item);
			my $idx = $self->_bindings_list->InsertItem($item);

			$self->_bindings_list->SetItem( $idx, 1, $menu_item_shortcut );
		}
	}

	if ( $self->_bindings_list->GetItemCount() ) {
		$self->_bindings_list->Select( 0, 1 );
	}

	return;
}


1;

__END__
=pod

=head1 NAME

Padre::Plugin::Ecliptic::QuickAssistDialog - Quick assist autocomplete dialog

=head1 VERSION

version 0.23

=head1 AUTHOR

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ahmad M. Zawawi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

