package Padre::Plugin::Ecliptic::QuickModuleAccessDialog;
BEGIN {
  $Padre::Plugin::Ecliptic::QuickModuleAccessDialog::VERSION = '0.23';
}

# ABSTRACT: Quick module autocomplete dialog

use warnings;
use strict;

# module imports
use Padre::Wx ();

# is a subclass of Wx::Dialog
use base 'Wx::Dialog';

# accessors
use Class::XSAccessor accessors => {
	_plugin       => '_plugin',       # Plugin object
	_sizer        => '_sizer',        # window sizer
	_search_text  => '_search_text',  # search text control
	_matches_list => '_matches_list', # matches list
	_status_text  => '_status_text',  # status label
	_modules      => '_modules',      # modules list
};

# -- constructor
sub new {
	my ( $class, $plugin, %opt ) = @_;

	# create object
	my $self = $class->SUPER::new(
		$plugin->main,
		-1,
		Wx::gettext('Quick Module Access'),
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

	# Open the selected module in POD browser if the user pressed OK
	my $selection       = $self->_matches_list->GetSelection;
	my $selected_module = $self->_matches_list->GetClientData($selection);
	if ($selected_module) {
		Wx::Event::EVT_IDLE(
			$self,
			sub {

				#print "Show DocBrowser for '$selected_module'\n";
				Padre->ide->wx->main->help($selected_module);
				Wx::Event::EVT_IDLE( $self, undef );
			},
		);
	}

	$self->Destroy;

	return;
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

	# center the dialog
	$self->Centre;

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

	# search textbox
	my $search_label = Wx::StaticText->new(
		$self, -1,
		Wx::gettext('&Type a module name to access:')
	);
	$self->_search_text( Wx::TextCtrl->new( $self, -1, '' ) );

	# matches result list
	my $matches_label = Wx::StaticText->new(
		$self, -1,
		Wx::gettext('&Matching modules:')
	);
	$self->_matches_list(
		Wx::ListBox->new(
			$self, -1, [ -1, -1 ], [ 400, 300 ], [],
			Wx::wxLB_SINGLE
		)
	);

	# Shows how many items are selected and information about what is selected
	$self->_status_text( Wx::StaticText->new( $self, -1, '' ) );

	$self->_sizer->AddSpacer(10);
	$self->_sizer->Add( $search_label,        0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $self->_search_text,  0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$self->_sizer->Add( $matches_label,       0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $self->_matches_list, 0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $self->_status_text,  0, Wx::wxALL | Wx::wxEXPAND, 10 );

	$self->_setup_events;

	return;
}

#
# Adds various events
#
sub _setup_events {
	my $self = shift;

	Wx::Event::EVT_CHAR(
		$self->_search_text,
		sub {
			my $this  = shift;
			my $event = shift;
			my $code  = $event->GetKeyCode;

			if ( $code == Wx::WXK_DOWN ) {
				$self->_matches_list->SetFocus;
			}

			$event->Skip(1);
		}
	);

	Wx::Event::EVT_TEXT(
		$self,
		$self->_search_text,
		sub {

			$self->_update_matches_list_box;

			return;
		}
	);

	Wx::Event::EVT_LISTBOX(
		$self,
		$self->_matches_list,
		sub {

			my $selection = $self->_matches_list->GetSelection;
			if ( $selection != Wx::wxNOT_FOUND ) {
				$self->_status_text->SetLabel( $self->_matches_list->GetString($selection) );
			}

			return;
		}
	);

	Wx::Event::EVT_LISTBOX_DCLICK(
		$self,
		$self->_matches_list,
		sub {
			$self->_on_ok_button_clicked();
			$self->EndModal(0);
		}
	);

	Wx::Event::EVT_IDLE(
		$self,
		sub {

			# update matches list
			$self->_update_matches_list_box;

			# focus on the search text box
			$self->_search_text->SetFocus;

			# unregister from idle event
			Wx::Event::EVT_IDLE( $self, undef );
		}
	);
}

#
# Update matches list box from matched files list
#
sub _update_matches_list_box {
	my $self = shift;

	my $search_expr = $self->_search_text->GetValue;

	#quote the search string to make it safer
	$search_expr = quotemeta $search_expr;

	#Populate the list box now
	$self->_matches_list->Clear;
	my $pos = 0;

	unless ( $self->_modules ) {
		$self->_status_text->SetLabel( Wx::gettext("Reading modules. Please wait...") );
		my %seen;
		for my $path (@INC) {
			for my $file ( File::Find::Rule->name('*.pm')->in($path) ) {
				my $module = substr( $file, length($path) + 1 );
				$module =~ s/.pm$//;
				$module =~ s{[\\/]}{::}g;
				$seen{$module}++;
			}
		}
		my @modules = sort keys %seen;
		$self->_modules( \@modules );
		$self->_status_text->SetLabel( Wx::gettext("Finished Searching") );
	}

	foreach my $module ( @{ $self->_modules } ) {
		if ( $module =~ /$search_expr/i ) {
			$self->_matches_list->Insert( $module, $pos, $module );
			$pos++;
		}
	}

	if ( $pos > 0 ) {
		$self->_matches_list->Select(0);
		$self->_status_text->SetLabel( "" . ( $pos + 1 ) . Wx::gettext(' item(s) found') );
	} else {
		$self->_status_text->SetLabel( Wx::gettext('No items found') );
	}

	return;
}

1;

__END__
=pod

=head1 NAME

Padre::Plugin::Ecliptic::QuickModuleAccessDialog - Quick module autocomplete dialog

=head1 VERSION

version 0.23

=head1 AUTHOR

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ahmad M. Zawawi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

