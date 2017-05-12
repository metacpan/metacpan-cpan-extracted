package Padre::Plugin::Vi;
use strict;
use warnings;
use 5.008005;

use base 'Padre::Plugin';

use Scalar::Util qw(refaddr);
use Padre::Util ('_T');
use Padre::Constant ();

our $VERSION = '0.23';

=head1 NAME

Padre::Plugin::Vi - vi keyboard for Padre

=head1 DESCRIPTION

Once installed and enabled the user is in full vi-emulation mode,
which was partially implemented.

The 3 basic modes of vi are in development:

When you turn on vi-mode, or load Padre with vi-mode already enabled
you reach the normal navigation mode of vi.

We don't plan to implement many of the configuration options of vi. 
Even parts that are going to be implemented will not use the same method
of configuration.

That said, we are planning to add looking for vi configuration options in
the source file so the editor can set its own configuration based on the
vi configuration options.


The following are implemented:

=head2 Navigation mode

=over

=item *

in navigation mode catch ':' and open the command line

=item *

l,h,k,j  - (right, left, up, down) navigation 

4 arrows also work

Number prefix are allowed in both the 4 letter and the 4 arrows

=item *

PageUp, PageDown

=item *

Home - goto first character on line

=item *

End - goto last character on line

=item *

^ - (shift-6) jump to beginning of line

=item *

$ - (shift-4) jump to end of line

=item *

v - visual mode, to start marking section

 d - delete the selection
 x - delete the selection
 y - yank the selection
 v - stop the visual mode, remove selection


=item *

p - paste below

P - paste above

=item *

Ctrl-6 - jump to last window edited. (This is inherited from Padre)

=item *

a - switch to insert mode after the current character

=item *

i - switch to insert mode before the current character

TODO this is currently step one character back as the caret is not
ON a caracter but between two.

=item *

o - add an empty line below current line and switch to insert mode

O - add an empty line above current line and switch to insert mode

=item *

x - delete current character

Nx - delete N characters

=item *

dd - delete current line

Ndd - (N any number) delete N lines

d$ - delete till end of line

Ndw - delete N word

=item *

yy - yank (copy) current line to buffer

Nyy - yank (copy) N lines to buffer

y$ - yank till end of line

Nyw - yank N words

=item *

u - undo last editing

=item *

J - (shift-j) join lines, join the next line after the current one

=item *

ZZ - save file and close editor

=item *

42G - jump to line 42

G - jump to last line

=item *

w, Nw - next word, forward N words

=item *

b, Nb - back one word, back N words

=back

=head2 Insert mode

=over 4

=item *

ESC moves to navigation mode

=item *

Ctrl-p - autocompletion (inherited from Padre)

=item *

For now at least, everything else should work as in standard Padre.

=back

=head2 Command mode

=over 4

=item *

:w - write current buffer

=item *

:e filename - open file for editing

TAB completition of directory and filenames

=item *

:42 - goto line 42 

(we have it in generalized form, you can type any number there :)

=item *

:q - exit

=item *

:wq - write and exit

:bN to switch buffer N

TODO: it is not working the same way as in vi, 
first of all numbers are from and if a file is closed
the buffers are renumbered. If we really want to
support this option we might need to have our own
separate mapping of numbers to buffers and files.

=back

=head1 TODO

Better indication that Padre is in vi-mode.

Change the cursor for navigation mode and back to insert mode.
(fix i)

Integrate command line pop-up
move it to the bottom of the window
make it come up faster (show/hide instead of create/destroy?)
(maybe actually we should have it integrated it into the main GUI
and add it as another window under or above the output window?)
Most importantly, make it faster to come up


/ and search connect it to the new (and yet experimental search)



r for replacing current character
:q! - discard changes and exit

:e!
:ls and


=cut

sub padre_interfaces {
	'Padre::Plugin' => 0.43;
}

sub plugin_enable {
	my ($self) = @_;

	require Padre::Plugin::Vi::Editor;
	require Padre::Plugin::Vi::CommandLine;

	#	foreach my $editor ( Padre->ide->wx->main->pages ) {
	#		$self->editor_enable($editor);
	#	}
}

sub plugin_disable {
	my ($self) = @_;

	foreach my $editor ( Padre->ide->wx->main->pages ) {
		$self->editor_stop($editor);
	}
	delete $INC{"Padre/Plugin/Vi/Editor.pm"};
	delete $INC{"Padre/Plugin/Vi/CommandLine.pm"};
	return;
}

sub editor_enable {
	my ( $self, $editor, $doc ) = @_;

	$self->{editor}{ refaddr $editor} = Padre::Plugin::Vi::Editor->new($editor);

	Wx::Event::EVT_KEY_DOWN( $editor, sub { $self->evt_key_down(@_) } );
	Wx::Event::EVT_CHAR( $editor, sub { $self->evt_char(@_) } );

	return 1;
}

sub editor_stop {
	my ( $self, $editor, $doc ) = @_;

	delete $self->{editor}{ refaddr $editor};
	Wx::Event::EVT_KEY_DOWN( $editor, undef );
	Wx::Event::EVT_CHAR( $editor, undef );

	return 1;
}

sub menu_plugins_simple {
	return ( "Vi mode" => [ _T('About') => \&about ] );
}

sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Vi");
	$about->SetDescription("Try to emulate the vi modes of operation\n");
	$about->SetVersion($Padre::Plugin::Vi::VERSION);
	$about->SetCopyright( _T("Copyright 2008 Gabor Szabo") );

	# Only Unix/GTK native about box supports websites
	if (Padre::Constant::WXGTK) {
		$about->SetWebSite("http://padre.perlide.org/");
	}

	$about->AddDeveloper("Gabor Szabo");

	Wx::AboutBox($about);
	return;
}

sub evt_key_down {
	my ( $self, $editor, $event ) = @_;

	my $mod = $event->GetModifiers || 0;
	my $code = $event->GetKeyCode;

	#print("key: '$mod', '$code'\n");
	if ( 32 <= $code and $code <= 127 ) {
		$event->Skip;
		return;
	}

	my $skip = $self->{editor}{ refaddr $editor}->key_down( $mod, $code );
	$event->Skip($skip);
	return;
}

sub evt_char {
	my ( $self, $editor, $event ) = @_;

	my $mod = $event->GetModifiers || 0;
	my $code = $event->GetKeyCode;

	#printf("char: '$mod', '$code' '%s'\n", chr($code));
	if ( 32 <= $code and $code <= 127 ) {
		my $skip = $self->{editor}{ refaddr $editor}->get_char( $mod, $code, chr($code) );
		$event->Skip($skip);
	}
	return;
}

1;

# Copyright 2008-2010 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
