package Padre::Plugin::Vi::Editor;
use strict;
use warnings;

my %subs;

use List::Util ();
use Padre::Wx  ();
use Padre::Plugin::Vi::CommandLine;

our $VERSION = '0.23';

sub new {
	my ( $class, $editor ) = @_;
	my $self = bless {}, $class;

	$self->{insert_mode} = 0;
	$self->{buffer}      = '';
	$self->{visual_mode} = 0;
	$self->{editor}      = $editor;

	return $self;
}

sub editor { return $_[0]->{editor} }

# TODO:  Should i write the combinations as anonym function,
#        if they are too long to suit in a line?
$subs{CHAR} = {

	# movements
	l   => \&move_right,
	h   => \&move_left,
	k   => \&line_up,
	j   => \&line_down,
	w   => \&word_right,
	b   => \&word_left,
	e   => \&word_right_end,
	' ' => \&move_right,

	G => \&goto_line,

	# selection
	v => \&visual_mode,
	### switch to insert mode
	a => \&append_mode,
	A => \&append_line_end,
	i => \&insert_mode,
	I => \&insert_at_first_non_blank,
	o => \&open_below,
	O => \&open_above,

	### editing from navigation mode
	x => \&delete_char,
	u => \&undo,
	p => \&paste_after,
	P => \&paste_before,

	J => \&join_lines,

	dd   => \&delete_lines,
	dw   => \&delete_words,
	'd$' => \&delete_till_end_of_line,
	'D'  => \&delete_till_end_of_line,
	yy   => \&yank_lines,
	yw   => \&yank_words,
	'y$' => \&yank_till_end_of_line,

	'c$' => \&change_till_end_of_line,
	'C'  => \&change_till_end_of_line,
	cw   => \&change_words,

	ZZ  => \&save_and_quit,
	'$' => \&goto_end_of_line,      # Shift-4 is $   End
	'^' => \&goto_first_non_blank,
	'0' => \&goto_beginning_of_line,

	'{' => \&paragraph_up,
	'}' => \&paragraph_down,
};

$subs{PLAIN} = {

	# movements
	Wx::WXK_RIGHT => $subs{CHAR}{l},
	Wx::WXK_LEFT  => $subs{CHAR}{h},
	Wx::WXK_UP    => $subs{CHAR}{k},
	Wx::WXK_DOWN  => $subs{CHAR}{j},

	Wx::WXK_PAGEUP => sub {
		my ( $self, $count ) = @_; # TODO use $count ??
		if ( $self->{visual_mode} ) {
			$self->{editor}->PageUpExtend;
		} else {
			$self->{editor}->PageUp;
		}
	},
	Wx::WXK_PAGEDOWN => sub {
		my ( $self, $count ) = @_; # TODO use $count ??
		if ( $self->{visual_mode} ) {
			$self->{editor}->PageDownExtend;
		} else {
			$self->{editor}->PageDown;
		}
	},
	Wx::WXK_HOME => \&goto_beginning_of_line,
	Wx::WXK_END  => \&goto_end_of_line,
};

$subs{VISUAL} = {
	d => \&delete_selection,
	x => \&delete_selection,
	y => \&yank_selection,
	v => sub { },           # just end visual mode
};

$subs{SHIFT} = {};

# the following does not yet work as we need to neuralize the Ctrl-N of Padre
# before we can see this command
$subs{COMMAND} = {
	ord('N') => sub {       # autocompletion
		print "Ctrl-N $_[0]\n";
		my $main = Padre->ide->wx->main;
		$main->on_autocompletition;
	},
};

# returning the value that will be given to $event->Skip()
sub key_down {
	my ( $self, $mod, $code ) = @_;

	if ( $code == Wx::WXK_ESCAPE ) {
		$self->{insert_mode} = 0;
		$self->{buffer}      = '';
		$self->{visual_mode} = 0;
		$self->remove_selection;
		return 0;
	}

	if ( $self->{insert_mode} ) {
		return 1;
	}

	# list of keys we don't want to implement but pass back to the STC to handle
	#	my %skip = map { $_ => 1 }
	#		(Wx::WXK_PAGEDOWN, Wx::WXK_HOME);
	#
	#	if ($skip{$code}) {
	#		return 1;
	#	}
	#

	# remove the bit ( Wx::wxMOD_META) set by Num Lock being pressed on Linux
	$mod = $mod & ( Wx::wxMOD_ALT() + Wx::wxMOD_CMD() + Wx::wxMOD_SHIFT() );

	my $modifier = (
		  $mod == Wx::wxMOD_SHIFT() ? 'SHIFT'
		: $mod == Wx::wxMOD_CMD()   ? 'COMMAND'
		: 'PLAIN'
	);

	if ( my $thing = $subs{$modifier}{$code} ) {
		my $sub;
		if ( not ref $thing ) {
			if ( $subs{$modifier}{$thing} and ref $subs{$modifier}{$thing} and ref $subs{$modifier}{$thing} eq 'CODE' )
			{
				$sub = $subs{$modifier}{$thing};
			} else {
				warn "Invalid entry in 'subs' hash  in code '$thing' referenced from '$code'";
			}
		} elsif ( ref $subs{$modifier}{$code} eq 'CODE' ) {
			$sub = $thing;
		} else {
			warn "Invalid entry in 'subs' hash for code '$code'";
		}

		my $count = $self->{buffer} =~ /^(\d+)/ ? $1 : 1;
		if ($sub) {
			$sub->( $self, $count );
		}
		$self->{buffer} = '';
		return 0;
	}

	# left here to easily find extra keys we still need to implement:
	#printf("key '%s' '%s'\n", $mod, $code);
	return 0;
}

sub get_char {
	my ( $self, $mod, $code, $chr ) = @_;

	# print "CHR $chr\n" if $chr;
	if ( $self->{insert_mode} ) {
		return 1;
	}

	$self->{buffer} .= $chr;

	#print "Buffer: '$self->{buffer}'\n";
	if ( $self->{visual_mode} ) {
		if ( $self->{buffer} =~ /^[dvxy]$/ ) {
			my $command = $self->{buffer};
			if ( $subs{VISUAL}{$command} ) {
				$subs{VISUAL}{$command}->($self);
				$self->{buffer}      = '';
				$self->{visual_mode} = 0;
				$self->remove_selection;
			}
			return 0;
		}
	}

	if ( $chr eq ':' ) {
		Padre::Plugin::Vi::CommandLine->show_prompt();
		$self->{buffer} = '';
		return 0;
	}
	if (   $self->{buffer} =~ /^()(0)$/
		or $self->{buffer} =~ /^(\d*)([wbelhjkvaAiIoxupOJPG\$^{}CD ])$/
		or $self->{buffer} =~ /^(\d*)(ZZ|d[dw\$]|y[yw\$]|c[w\$])$/ )
	{
		my $count   = $1;
		my $command = $2;

		# special case default value
		if ( $command eq 'G' ) {
			$count ||= $self->{editor}->GetLineCount;
		} else {
			$count ||= 1;
		}

		if ( $subs{CHAR}{$command} ) {
			$subs{CHAR}{$command}->( $self, $count );
			$self->{buffer} = '';
		}
		return 0;
	}

	# left here to easily find extra keys we still need to implement:
	#printf("chr '%s' '%s'\n", $mod, $chr);
	return 0;
}

sub line_down {
	my ( $self, $count ) = @_;
	if ( $self->{visual_mode} ) {
		$self->{editor}->LineDownExtend for 1 .. $count;
		return;
	}

	#$self->{editor}->LineDown; # is this broken?
	my $pos       = $self->{editor}->GetCurrentPos;
	my $line      = $self->{editor}->LineFromPosition($pos);
	my $last_line = $self->{editor}->LineFromPosition( length $self->{editor}->GetText );
	my $toline    = List::Util::min( $line + $count, $last_line );
	$self->line_up_down( $pos, $line, $toline );
	return;
}

sub line_up {
	my ( $self, $count ) = @_;

	if ( $self->{visual_mode} ) {
		$self->{editor}->LineUpExtend for 1 .. $count;
		return;
	}

	#$self->{editor}->LineUp; # is this broken?
	my $pos    = $self->{editor}->GetCurrentPos;
	my $line   = $self->{editor}->LineFromPosition($pos);
	my $toline = List::Util::max( $line - $count, 0 );
	$self->line_up_down( $pos, $line, $toline );
	return;
}

sub line_up_down {
	my ( $self, $pos, $line, $toline ) = @_;

	my $to;
	if ( $self->{end_pressed} ) {
		$to = $self->{editor}->GetLineEndPosition($toline);
	} else {
		$to = $self->{editor}->FindColumn( $toline, $self->{editor}->GetColumn($pos) );
	}
	$self->{editor}->GotoPos($to);
	return;
}

sub goto_end_of_line {
	my ($self) = @_;
	$self->{end_pressed} = 1;
	if ( $self->{visual_mode} ) {
		$self->{editor}->LineEndExtend();
	} else {
		$self->{editor}->LineEnd();
	}
}

sub goto_beginning_of_line {
	my ($self) = @_;
	$self->{end_pressed} = 0;
	if ( $self->{visual_mode} ) {
		$self->{editor}->HomeExtend;
	} else {
		$self->{editor}->Home;
	}
}

sub goto_first_non_blank {

	# goto first non-blank char

	# FIXME: may be the function name is too long :(

	my ($self) = @_;
	my $line   = $self->{editor}->GetCurrentLine;
	my $text   = $self->{editor}->_get_line_by_number($line);

	$text =~ /^(\s*)/;
	my $offset = length($1) + 1;                          # + 1 for normal mode !
	my $start  = $self->{editor}->PositionFromLine($line);

	if ( $self->{visual_mode} ) {
		$self->{editor}->HomeExtend;
		$self->{editor}->CharRightExtend() for 1 .. $offset;
	} else {
		$self->{editor}->GotoPos( $start + $offset );
	}
}

sub select_rows {
	my ( $self, $count ) = @_;
	my $line  = $self->{editor}->GetCurrentLine;
	my $start = $self->{editor}->PositionFromLine($line);
	my $end   = $self->{editor}->PositionFromLine( $line + $count );

	#my $end   = $self->{editor}->GetLineEndPosition($line+$count-1);
	$self->{editor}->GotoPos($start);
	$self->{editor}->SetTargetStart($start);
	$self->{editor}->SetTargetEnd($end);
	$self->{editor}->SetSelection( $start, $end );
}

sub move_right {
	my ( $self, $count ) = @_;

	#print "COUNT $count\n";
	$self->{end_pressed} = 0;
	if ( $self->{visual_mode} ) {
		$self->{editor}->CharRightExtend() for 1 .. $count;
	} else {
		my $pos = $self->{editor}->GetCurrentPos;
		$self->{editor}->GotoPos( $pos + $count );
	}
}

sub move_left {
	my ( $self, $count ) = @_;
	$self->{end_pressed} = 0;
	if ( $self->{visual_mode} ) {
		$self->{editor}->CharLeftExtend for 1 .. $count;
	} else {
		my $pos = $self->{editor}->GetCurrentPos;
		$self->{editor}->GotoPos( List::Util::max( $pos - $count, 0 ) );
	}
}

sub visual_mode {
	my ( $self, $count ) = @_;
	my $main = Padre->ide->wx->main;
	$self->{editor}->text_selection_mark_start($main);
	$self->{editor}->CharLeftExtend();
	$self->{visual_mode} = 1;
}

# switch to insert mode
sub append_mode { # append
	my ( $self, $count ) = @_; # TODO use $count ??
	$self->{insert_mode} = 1;

	# change cursor
}

sub append_line_end {          # combination with $ and a
	my ($self) = @_;           # do NOT use $count
	$self->goto_end_of_line;
	$self->{insert_mode} = 1;
}

sub insert_mode {              # insert
	my ( $self, $count ) = @_; # use $count ?
	$self->{insert_mode} = 1;
	my $pos = $self->{editor}->GetCurrentPos;
	$self->{editor}->GotoPos( $pos - 1 );

	# change cursor
}

sub insert_at_first_non_blank {
	my ($self) = @_;

	$self->goto_first_non_blank;
	$self->insert_mode;
}

sub open_below {
	my ( $self, $count ) = @_; # TODO use $count ??
	$self->{insert_mode} = 1;
	my $line = $self->{editor}->GetCurrentLine;
	my $end  = $self->{editor}->GetLineEndPosition($line);

	# go to end of line, insert newline
	$self->{editor}->GotoPos($end);
	$self->{editor}->NewLine;

	# change cursor
}

sub open_above {
	my ( $self, $count ) = @_;
	$self->{insert_mode} = 1;
	my $line  = $self->{editor}->GetCurrentLine;
	my $start = $self->{editor}->PositionFromLine($line);

	# go to beginning of line, insert newline, go to previous line
	$self->{editor}->GotoPos($start);
	$self->{editor}->NewLine;
	$self->{editor}->GotoPos($start);

	# change cursor
}

sub delete_char {
	my ( $self, $count ) = @_;
	my $pos = $self->{editor}->GetCurrentPos;
	$self->{editor}->SetTargetStart($pos);
	$self->{editor}->SetTargetEnd( $pos + $count );
	$self->{buffer} = '';
	$self->{editor}->ReplaceTarget('');
}

sub undo {
	my ( $self, $count ) = @_;
	$self->{editor}->Undo;
}

sub paste_after {
	my ( $self, $count ) = @_;
	my $text = Padre::Wx::Editor::get_text_from_clipboard();
	if ( $text =~ /\n/ ) {
		my $line  = $self->{editor}->GetCurrentLine;
		my $start = $self->{editor}->PositionFromLine( $line + 1 );
		$self->{editor}->GotoPos($start);
	}
	$self->{editor}->Paste;
}

sub paste_before {
	my ( $self, $count ) = @_;
	my $text = Padre::Wx::Editor::get_text_from_clipboard();
	if ( $text =~ /\n/ ) {
		my $line  = $self->{editor}->GetCurrentLine;
		my $start = $self->{editor}->PositionFromLine($line);
		$self->{editor}->GotoPos($start);
	} else {
		my $pos = $self->{editor}->GetCurrentPos;
		$self->{editor}->GotoPos( $pos - 1 );
	}
	$self->{editor}->Paste;
}

sub join_lines {
	my ( $self, $count ) = @_;
	my $main = Padre->ide->wx->main;
	$main->on_join_lines;
}

sub goto_line {
	my ( $self, $count ) = @_; # TODO: special case for count !!
	$self->{editor}->GotoLine( $count - 1 );
	$self->{buffer} = '';
}

sub delete_lines {
	my ( $self, $count ) = @_;
	$self->select_rows($count);
	$self->{editor}->Cut;
}

sub delete_till_end_of_line {
	my ( $self, $count ) = @_;

	#$self->{editor}->DelLineRight; # would be nice, but it does not put the strin in the clipboard

	$self->select_till_end_of_line;
	$self->{editor}->Cut;
}

sub yank_till_end_of_line {
	my ( $self, $count ) = @_;

	$self->select_till_end_of_line;
	$self->{editor}->Copy;
}

sub select_till_end_of_line {
	my ($self) = @_;
	my $line   = $self->{editor}->GetCurrentLine;
	my $start  = $self->{editor}->GetCurrentPos;
	my $end    = $self->{editor}->GetLineEndPosition($line);

	$self->{editor}->SetTargetStart($start);
	$self->{editor}->SetTargetEnd($end);
	$self->{editor}->SetSelection( $start, $end );

	return;
}

sub delete_words {
	my ( $self, $count ) = @_;
	$self->{editor}->WordRightEndExtend for 1 .. $count;
	$self->{editor}->Cut;
	return;
}

sub yank_words {
	my ( $self, $count ) = @_;
	$self->{editor}->WordRightEndExtend for 1 .. $count;
	$self->{editor}->Copy;
	return;
}

sub yank_lines {
	my ( $self, $count ) = @_;
	$self->select_rows($count);
	$self->{editor}->Copy;
	$self->remove_selection;
}

sub remove_selection {
	my ($self) = @_;
	$self->{editor}->SetSelectionStart( $self->{editor}->GetSelectionEnd );
	return;
}

sub delete_selection {
	my ($self) = @_;
	$self->{editor}->Cut;
}

sub yank_selection {
	my ($self) = @_;
	$self->{editor}->Copy;
}

sub save_and_quit {
	my ($self) = @_;
	my $main = Padre->ide->wx->main;
	$main->on_save;
	$main->Close;
	return;
}

sub word_right {
	my ( $self, $count ) = @_;
	$self->{editor}->WordRight for 1 .. $count;
}

sub word_left {
	my ( $self, $count ) = @_;
	$self->{editor}->WordLeft for 1 .. $count;
}

sub word_right_end {
	my ( $self, $count ) = @_;
	$self->{editor}->WordRightEnd for 1 .. $count;
}

sub paragraph_up {
	my ( $self, $count ) = @_;

	my $pos     = $self->{editor}->GetCurrentPos;
	my $line_no = $self->{editor}->LineFromPosition($pos);

	while ( $line_no-- > 0 && $count ) {
		my $line = $self->{editor}->GetLine($line_no);
		if ( $line =~ /^\s*$/ ) {
			$count--;
			last if $count < 1;
		}
	}
	$self->{editor}->GotoLine($line_no);
}

sub paragraph_down {
	my ( $self, $count ) = @_;

	my $pos       = $self->{editor}->GetCurrentPos;
	my $line_no   = $self->{editor}->LineFromPosition($pos);
	my $num_lines = $self->{editor}->GetLineCount;

	while ( $line_no++ < $num_lines && $count ) {
		my $line = $self->{editor}->GetLine($line_no);
		if ( $line =~ /^\s*$/ ) {
			$count--;
			last if $count < 1;
		}
	}
	$self->{editor}->GotoLine($line_no);
}

sub change_words {
	my ( $self, $count ) = @_;

	$self->delete_words($count);
	$self->{insert_mode} = 1;
}

sub change_till_end_of_line {
	my ( $self, $count ) = @_;

	$self->delete_till_end_of_line($count);
	$self->{insert_mode} = 1;
}


1;

# Copyright 2008-2010 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
