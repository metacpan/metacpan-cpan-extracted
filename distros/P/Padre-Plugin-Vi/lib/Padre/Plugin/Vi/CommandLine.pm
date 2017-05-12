package Padre::Plugin::Vi::CommandLine;

use warnings;
use strict;

use Cwd              ();
use Wx::Perl::Dialog ();
use Padre::Wx        ();
use File::Spec       ();
use File::Basename   ();

use Padre::Plugin::Vi::TabCompletition qw(clear_tab handle_tab set_original_cwd);

=head1 NAME

Padre::Plugin::Vi::CommandLine - part of the vi plugin in Padre

=cut

our $VERSION = '0.23';

=head1 SYNOPSIS

Install L<Padre>, install this plug-in. 

=head1 WARNING 

The module is still experimental

=head1 DESCRIPTION


When you select the menu item or press the hot-key you should see a new window with
a place to enter text and an OK and Cancel buttons.

The text entry place is sort-of a command line.

Currently available commands are based on the vi command mode.

=over 4

=item e path/to/file

open a file for editing, supports TAB completion

=item w

write a file

It does NOT support save-as or providing filename.

=back

=cut

my @layout = (
	[   [ 'Wx::TextCtrl', 'entry',  '' ],
		[ 'Wx::Button',   'ok',     Wx::wxID_OK ],
		[ 'Wx::Button',   'cancel', Wx::wxID_CANCEL ],
	]
);
my $dialog;

sub dialog {
	my ($class) = @_;

	my $main = Padre->ide->wx->main;
	if ( not $dialog ) {
		$dialog = Wx::Perl::Dialog->new(
			parent => $main->{notebook},
			title  => "Command Line",
			layout => \@layout,
			width  => [500],
		);
		$dialog->{_widgets_}{entry}->SetFocus;
		$dialog->{_widgets_}{ok}->SetDefault;
		Wx::Event::EVT_CHAR( $dialog->{_widgets_}{entry}, \&on_key_pressed );
	}

	return $dialog;
}

sub show_prompt {
	my ($class) = @_;

	my $main   = Padre->ide->wx->main;
	my $dialog = $class->dialog();

	#	print "Pos: ", join ":", $main->{notebook}->GetScreenPosition, "\n";
	#	print "Size: ", join ":", $main->{notebook}->GetSizeWH, "\n";
	$dialog->{_widgets_}{entry}->SetValue('');

	#$dialog->SetPosition($main->{notebook}->GetScreenPosition);
	my $ret = $dialog->ShowModal;
	if ( $ret eq Wx::wxID_CANCEL ) {

		#$dialog->Hide;
		return;
	}

	my $cmd = $dialog->{_widgets_}{entry}->GetValue;
	if ( $cmd =~ /^e\s+(.*)/ and defined $1 ) {
		my $file = $1;

		# try to open file
		$main->setup_editor( File::Spec->catfile( Padre->ide->{original_cwd}, $file ) );
		$main->refresh_all;
	} elsif ( $cmd =~ /^b(\d+)$/ ) {
		$main->on_nth_pane($1);
	} elsif ( $cmd eq 'w' ) {
		$main->on_save;
	} elsif ( $cmd eq 'q' ) {
		$main->Close;
	} elsif ( $cmd eq 'wq' ) { #TODO shall this be save_all ?
		$main->on_save;
		$main->Close;
	} elsif ( $cmd =~ /^\d+$/ ) {
		Padre->ide->wx->main->current->editor->GotoLine( $cmd - 1 );
	} elsif ( $cmd =~ m{%s/} ) {
		my $editor = Padre->ide->wx->main->current->editor;
		my $text   = $editor->GetText;
		$cmd = substr( $cmd, 1 );
		eval "\$text =~ $cmd";
		if ($@) {
			Padre->ide->wx->main->error($@);
		} else {
			$editor->SetText($text);
		}
	}

	return;
}

sub on_key_pressed {
	my ( $text_ctrl, $event ) = @_;
	my $mod = $event->GetModifiers || 0;
	my $code = $event->GetKeyCode;

	# remove the bit ( Wx::wxMOD_META) set by Num Lock being pressed on Linux
	$mod = $mod & ( Wx::wxMOD_ALT() + Wx::wxMOD_CMD() + Wx::wxMOD_SHIFT() );

	# anything but TAB pressed
	if ( $code != Wx::WXK_TAB ) {
		clear_tab();
		$event->Skip(1);
		return;
	}

	set_original_cwd( Padre->ide->{original_cwd} );

	my $value = handle_tab( $text_ctrl->GetValue, ( $mod == Wx::wxMOD_SHIFT() ? 1 : 0 ) );
	return if not defined $value;

	$text_ctrl->SetValue($value);
	$text_ctrl->SetInsertionPointEnd;

	$event->Skip(0);
	return;
}

sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::CommandLine");
	$about->SetDescription("Experimental vi-like command line\n");

	#$about->SetVersion($Padre::VERSION);
	Wx::AboutBox($about);
	return;
}

=head1 AUTHOR

Gabor Szabo, C<< <szabgab at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to  L<http://padre.perlide.org/>. 
I will be notified, and then you'll automatically be notified of progress on your 
bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Padre::Plugin::CommandLine


You can also look for information at: 

L<http://padre.perlide.org/>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Gabor Szabo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
