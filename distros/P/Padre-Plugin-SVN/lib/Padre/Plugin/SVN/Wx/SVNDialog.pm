package Padre::Plugin::SVN::Wx::SVNDialog;


use 5.008;
use warnings;
use strict;

use Padre::Wx         ();
use Padre::Wx::Dialog ();
use Padre::Wx::Icon   ();

our $VERSION = '0.05';
our @ISA     = 'Wx::Dialog';

sub new {
	my $class    = shift;
	my $main     = shift;
	my $filePath = shift;
	my $log      = shift;
	my $type     = shift || '';
	my $getData  = shift;

	my $self = $class->SUPER::new(
		$main,
		-1,
		"SVN $type",
		[ -1,  -1 ],  # position
		[ 700, 600 ], # size - [wide,high]
	);
	$self->SetIcon(Padre::Wx::Icon::PADRE);
	
	if( lc($type) eq 'blame' ) {
		$self->build_blame_dialog($filePath, $log);
	}
	else {
		$self->build_dialog( $filePath, $log, $getData );
	}

	return $self;

}


sub build_dialog {
	my ( $self, $file, $log, $getData ) = @_;
	
	
	
	my $vbox = Wx::BoxSizer->new(Wx::wxVERTICAL);

	my $stTxtFile = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("File: $file"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		0,
		""
	);

	$vbox->Add( $stTxtFile, 0, Wx::wxEXPAND );

	#print "file: $file\n";
	#print "Log: $log\n";

	my $txtCtrl;
	if ($log) {
		$txtCtrl = Wx::TextCtrl->new(
			$self,
			-1,
			"$log",
			Wx::wxDefaultPosition,
			[ -1, -1 ],
			Wx::wxTE_MULTILINE | Wx::wxHSCROLL | Wx::wxVSCROLL | Wx::wxTE_WORDWRAP
		);
	}
	if ($getData) {

		#print "getting data\n";
		$txtCtrl = Wx::TextCtrl->new(
			$self,
			-1,
			"Commit Message",
			Wx::wxDefaultPosition,
			[ -1, -1 ],
			Wx::wxTE_MULTILINE | Wx::wxHSCROLL | Wx::wxVSCROLL | Wx::wxTE_WORDWRAP
		);
		$txtCtrl->SetSelection( -1, -1 );
		$txtCtrl->SetFocus;
		$self->{txtctrl} = $txtCtrl;
	}



	$vbox->Add( $txtCtrl, 1, Wx::wxEXPAND );

	my $btnBox     = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	my $pnlButtons = Wx::Panel->new(
		$self,
		-1, # id
		[ -1, -1 ], # position
		[ -1, -1 ], # size
		0           # border style
	);

	# button height is set to 40 simply to get them to look the same
	# in GTK.
	# not sure what this is going to look like in other window managers.
	if ($getData) {

		$self->{cancelled} = 0;
		my $btnCancel = Wx::Button->new( $pnlButtons, Wx::wxID_CANCEL, "Cancel", [ -1, -1 ], [ -1, 40 ] );
		Wx::Event::EVT_BUTTON( $self, $btnCancel, \&cancel_clicked );
		$btnBox->Add( $btnCancel, 1, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_RIGHT );

	}

	my $btnOK = Wx::Button->new( $pnlButtons, Wx::wxID_OK, "OK", [ -1, -1 ], [ -1, 40 ] );
	Wx::Event::EVT_BUTTON( $self, $btnOK, \&ok_clicked );

	$btnBox->Add( $btnOK, 1, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_RIGHT );


	$pnlButtons->SetSizer($btnBox);

	#$btnBox->Add( $pnlButtons, 0, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_RIGHT | Wx::wxEXPAND);
	$vbox->Add( $pnlButtons, 0, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_RIGHT );


	$self->SetSizer($vbox);

}


sub build_blame_dialog {
	
	my ( $self, $file, $log ) = @_;
	
	#$self->{_busyCursor} = Wx::BusyCursor->new();
	
	my $vbox = Wx::BoxSizer->new(Wx::wxVERTICAL);

	require Padre::Plugin::SVN::Wx::BlameTree;
	$self->{blame} = Padre::Plugin::SVN::Wx::BlameTree->new($self);
	$self->{blame}->populate($log);
	$vbox->Add( $self->{blame}, 0, Wx::wxEXPAND );

	#print "file: $file\n";
	#print "Log: $log\n";

	my $btnBox     = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	my $pnlButtons = Wx::Panel->new(
		$self,
		-1, # id
		[ -1, -1 ], # position
		[ -1, -1 ], # size
		0           # border style
	);

	# button height is set to 40 simply to get them to look the same
	# in GTK.
	# not sure what this is going to look like in other window managers.
	
	my $btnExpandAll = Wx::Button->new( $pnlButtons, -1, "Expand", [ -1, -1 ], [ -1, 40 ] );
	Wx::Event::EVT_BUTTON( $self, $btnExpandAll, \&expand_clicked );
	$btnBox->Add( $btnExpandAll, 1, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_LEFT );
	
	my $btnCollapseAll = Wx::Button->new( $pnlButtons, -1, "Collapse", [ -1, -1 ], [ -1, 40 ] );
	Wx::Event::EVT_BUTTON( $self, $btnCollapseAll, \&collapse_clicked );
	$btnBox->Add( $btnCollapseAll, 1, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_LEFT );
	


	my $btnOK = Wx::Button->new( $pnlButtons, Wx::wxID_OK, "OK", [ -1, -1 ], [ -1, 40 ] );
	Wx::Event::EVT_BUTTON( $self, $btnOK, \&ok_clicked );

	$btnBox->Add( $btnOK, 1, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_RIGHT );


	$pnlButtons->SetSizer($btnBox);

	#$btnBox->Add( $pnlButtons, 0, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_RIGHT | Wx::wxEXPAND);
	$vbox->Add( $pnlButtons, 0, Wx::wxALIGN_BOTTOM | Wx::wxALIGN_RIGHT );


	$self->SetSizer($vbox);
	#$self->{_busyCursor} = undef;
}

sub collapse_clicked {
	my( $self ) = @_;
	$self->{_busyCursor} = Wx::BusyCursor->new();
	$self->{blame}->CollapseAll();
	$self->{_busyCursor} = undef;
}
sub expand_clicked {
	my ($self) = @_;
	$self->{_busyCursor} = Wx::BusyCursor->new();
	$self->{blame}->ExpandAll();
	$self->{_busyCursor} = undef;
}

sub ok_clicked {
	my ($self) = @_;

	#print "OK Clicked\n";
	my $txt;
	if ( $self->{txtctrl} ) {

		#print "have to return data: " . $self->{txtctrl}->GetValue;
		$txt = $self->{txtctrl}->GetValue;
	}
	$self->Hide();
	$self->Destroy;
	return $txt;
}

sub cancel_clicked {
	my ($self) = @_;

	$self->{cancelled} = 1;
	#print "Cancel Clicked\n";
	$self->Hide();
	$self->Destroy;
	$self->{txtctrl}->SetValue("");

	return;

}

sub get_data {
	my ($self) = @_;

	#print "Getting Data: " . $self->{txtctrl}->GetValue . "\n";
	return $self->{txtctrl}->GetValue;

	#my $txt =  $self->{txtctrl}->GetValue;
	#use Data::Dumper;
	#print Dumper($txt);
	#return $txt ;

}



1;

=head1 NAME

Padre::Plugin::SVN::Wx::SVNDialog - Dialog for SVN tasks.

=head1 SYNOPSIS

Provides a Dialog specifically for the SVN Plugin.

=head1 REQUIREMENTS

Nil

=head1 AUTHOR

Peter Lavender, C<< <peter.lavender at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

