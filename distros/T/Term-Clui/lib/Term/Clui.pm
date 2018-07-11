# Term::Clui.pm
#########################################################################
#        This Perl module is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This module is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

package Term::Clui;
our $VERSION = '1.73';
my $stupid_bloody_warning = $VERSION;  # circumvent -w warning
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(ask ask_password ask_filename confirm
 choose help_text edit sorry view inform);
@EXPORT_OK = qw(beep tiview back_up get_default set_default timestamp);
%EXPORT_TAGS = (ALL => [@EXPORT,@EXPORT_OK]);

use 5.006;
no strict; no warnings;

my $have_Term_ReadKey = 1;
my $have_Term_Size = 0;
eval 'require "Term/ReadKey.pm"';
if ($@) {
	$have_Term_ReadKey = 0;
	$have_Term_Size = 1;
	eval 'require "Term/Size.pm"';
	if ($@) { $have_Term_Size = 0; }
}

my $Eflite;
my $Eflite_FH;  # open here at top-level so one sub can silence the previous
my $Espeak;
my $Espeak_PID;  # defined at top-level so one espeak can kill the previous
my $SpeakUpSilentFile;   # 1.62
if ($ENV{'CLUI_SPEAK'}) {  # 1.62 emacspeak not very relevant as a criterion
	for my $d ('/sys/accessibility', '/proc') {
		if (-w "$d/speakup/silent") {
			$SpeakUpSilentFile = "$d/speakup/silent"; break;
		}
	}
	$Eflite = &which('eflite');
	$Espeak = &which('espeak');
	if ($Eflite && !$Espeak) {   # 1.68 Espeak should be the default
		if (open($Eflite_FH,'|-',$Eflite)) {
			select((select($Eflite_FH), $| = 1)[0]); print $Eflite_FH q{};
		} else {
			warn "can't run $Eflite: $!\n";
		}
	} elsif (! $Espeak) {
		warn("Term::Clui warning: CLUI_SPEAK set; "
		. "but can't find eflite or espeak\n");
	}
}


# use open ':locale';  # the open pragma was introduced in 5.8.6
my $EncodingString = q{};
if (($ENV{LANG} =~ /utf-?8/i) || ($ENV{LC_TYPE} =~ /utf-?8/i)) {
	$EncodingString = ':encoding(utf8)';
}

# ------------------------ vt100 stuff -------------------------

$A_NORMAL    =  0;
$A_BOLD      =  1;
$A_UNDERLINE =  2;
$A_REVERSE   =  4;
$KEY_UP    = 0403;
$KEY_LEFT  = 0404;
$KEY_RIGHT = 0405;
$KEY_DOWN  = 0402;
$KEY_ENTER = "\r";
$KEY_INSERT = 0525;
$KEY_DELETE = 0524;
$KEY_HOME   = 0523;
$KEY_END    = 0522;
$KEY_PPAGE  = 0521;
$KEY_NPAGE  = 0520;
$KEY_BTAB   = 0541;
my $AbsCursX = 0; my $AbsCursY = 0; my $TopRow = 0; my $CursorRow;
my $LastEventWasPress = 0;  # in order to ignore left-over button-ups
my %SpecialKey = map { $_, 1 } (   # 1.51, used by ask to ignore these
	$KEY_UP, $KEY_LEFT, $KEY_RIGHT, $KEY_DOWN, $KEY_HOME, $KEY_END,
	$KEY_PPAGE, $KEY_NPAGE, $KEY_BTAB, $KEY_INSERT, $KEY_DELETE
);

my $irow; my $icol;   # maintained by &puts, &up, &down, &left and &right
sub puts   { my $s = join q{}, @_;
	$irow += ($s =~ tr/\n/\n/);
	if ($s =~ /\r\n?$/) { $icol = 0;
	} else { $icol += length($s);
	}
	print TTY $s;
}
# could terminfo sgr0, bold, rev, cub1, cuu1, cuf1, cud1 ...
sub attrset { my $attr = $_[0];
	if (! $attr) {
		print TTY "\e[0m";
	} else {
		if ($attr & $A_BOLD)      { print TTY "\e[1m" };
		if ($attr & $A_REVERSE)   { print TTY "\e[7m" };
		if ($attr & $A_UNDERLINE) { print TTY "\e[4m" };
	}
}
sub beep     { print TTY "\07"; }
sub clear    { print TTY "\e[H\e[J"; }
sub clrtoeol { print TTY "\e[K"; }
sub black    { print TTY "\e[30m"; }
sub red      { print TTY "\e[31m"; }
sub green    { print TTY "\e[32m"; }
sub blue     { print TTY "\e[34m"; }
sub violet   { print TTY "\e[35m"; }

sub getc_wrapper { my $timeout = 0 + $_[0];
	if ($have_Term_ReadKey) {
		return Term::ReadKey::ReadKey($timeout, *TTYIN);
	} else {
		#if ($timeout > 0.00001) {  # doesn't seem to work on openbsd...
		#	my $rin = q{};
		#	vec($rin,fileno(TTYIN),1) = 1;
		#	my $nfound = select($rin, undef, undef, $timeout);
		#	if (!$nfound) { return undef; }
		#}
		return getc(TTYIN);
	}
}

sub getch {
	my $c = getc_wrapper(0);
	if ($c eq "\e") {
		$c = getc_wrapper(0.10);

		if (! defined $c) { return("\e"); }
		if ($c eq 'A') { return($KEY_UP); }
		if ($c eq 'B') { return($KEY_DOWN); }
		if ($c eq 'C') { return($KEY_RIGHT); }
		if ($c eq 'D') { return($KEY_LEFT); }
		if ($c eq '2') { getc_wrapper(0); return($KEY_INSERT); }
		if ($c eq '3') { getc_wrapper(0); return($KEY_DELETE); } # 1.54
		if ($c eq '5') { getc_wrapper(0); return($KEY_PPAGE); }
		if ($c eq '6') { getc_wrapper(0); return($KEY_NPAGE); }
		if ($c eq 'Z') { return($KEY_BTAB); }
		if ($c eq 'O') {   # 1.68 Haiku wierdness, inherited from an old Suse
			$c = getc_wrapper(0);
			if ($c eq 'A') { return($KEY_UP); }    # 1.68
			if ($c eq 'B') { return($KEY_DOWN); }  # 1.68
			if ($c eq 'C') { return($KEY_RIGHT); } # 1.68
			if ($c eq 'D') { return($KEY_LEFT); }  # 1.68
			if ($c eq 'F') { return($KEY_END); }   # 1.68
			if ($c eq 'H') { return($KEY_HOME); }  # 1.68
			return($c);
		}
		if ($c eq '[') {
			$c = getc_wrapper(0);
			if ($c eq 'A') { return($KEY_UP); }
			if ($c eq 'B') { return($KEY_DOWN); }
			if ($c eq 'C') { return($KEY_RIGHT); }
			if ($c eq 'D') { return($KEY_LEFT); }
			if ($c eq 'F') { return($KEY_END); }   # 1.67
			if ($c eq 'H') { return($KEY_HOME); }  # 1.67
            if ($c eq 'M') {   # mouse report - we must be in BYTES !
				# http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
				my $event_type = ord(getc_wrapper(0))-32;
				my $x = ord(getc_wrapper(0))-32;
				my $y = ord(getc_wrapper(0))-32;
				# my $shift   = $event_type & 0x04; # used by wm
				# my $meta	= $event_type & 0x08;   # used by wm
				# my $control = $event_type & 0x10; # used by xterm
				my $button_drag = ($event_type & 0x20) >> 5;
				my $button_pressed;
				my $low3bits = $event_type & 0x03;
				if ($low3bits == 0x03) {
					$button_pressed = 0;
				} else {  # button 4 means wheel-up, button 5 means wheel-down
					if ($event_type & 0x40) { $button_pressed = $low3bits + 4;
					} else { $button_pressed = $low3bits + 1;
					}
				}
				return handle_mouse($x,$y,$button_pressed,$button_drag)
				 || getch();
			}
			if ($c =~ /\d/) { my $c1 = getc_wrapper(0);
				if ($c1 eq '~') {
					if ($c eq '2') { return($KEY_INSERT);
					} elsif ($c eq '3') { return($KEY_DELETE);
					} elsif ($c eq '5') { return($KEY_PPAGE);
					} elsif ($c eq '6') { return($KEY_NPAGE);
					}
				} else {   # cursor-position report, response to \e[6n
					$AbsCursY = 0 + $c;
					while (1) {
						last if $c1 eq ';';
						$AbsCursY = 10*$AbsCursY + $c1;
						# debug("c1=$c1 AbsCursY=$AbsCursY");
						$c1 = getc(TTYIN);
					}
					$AbsCursX = 0;
					while (1) {
						$c1 = getc(TTYIN);
						last if $c1 eq 'R';
						$AbsCursX = 10*$AbsCursX + $c1;
					}
					return getch();
				}
            }
			if ($c eq 'Z') { return($KEY_BTAB); }
			return($c);
		}
		return($c);
	#} elsif ($c eq ord(0217)) {  # 1.50 BUG what?? never gets here...
	#	$c = getc_wrapper(0);
	#	if ($c eq 'A') { return($KEY_UP); }
	#	if ($c eq 'B') { return($KEY_DOWN); }
	#	if ($c eq 'C') { return($KEY_RIGHT); }
	#	if ($c eq 'D') { return($KEY_LEFT); }
	#	return($c);
	#} elsif ($c eq ord(0233)) {  # 1.50 BUG what?? never gets here...
	#	$c = getc_wrapper(0);
	#	if ($c eq 'A') { return($KEY_UP); }
	#	if ($c eq 'B') { return($KEY_DOWN); }
	#	if ($c eq 'C') { return($KEY_RIGHT); }
	#	if ($c eq 'D') { return($KEY_LEFT); }
	#	if ($c eq '5') { getc_wrapper(0); return($KEY_PPAGE); }
	#	if ($c eq '6') { getc_wrapper(0); return($KEY_NPAGE); }
	#	if ($c eq 'Z') { return($KEY_BTAB); }
	#	return($c);
	} else {
		return($c);
	}
}
sub up    {
	# if ($_[0] < 0) { &down(0 - $_[0]); return; }
	print TTY "\e[A" x $_[0]; $irow -= $_[0];
}
sub down  {
	# if ($_[0] < 0) { &up(0 - $_[0]); return; }
	print TTY "\n" x $_[0]; $irow += $_[0];
}
sub right {
	# if ($_[0] < 0) { &left(0 - $_[0]); return; }
	print TTY "\e[C" x $_[0]; $icol += $_[0];
}
sub left  {
	# if ($_[0] < 0) { &right(0 - $_[0]); return; }
	print TTY "\e[D" x $_[0]; $icol -= $_[0];
}
sub goto { my $newcol = shift; my $newrow = shift;
	if ($newcol == 0) { print TTY "\r" ; $icol = 0;
	} elsif ($newcol > $icol) { &right($newcol-$icol);
	} elsif ($newcol < $icol) { &left($icol-$newcol);
	}
	if ($newrow > $irow)      { &down($newrow-$irow);
	} elsif ($newrow < $irow) { &up($irow-$newrow);
	}
}
# sub move { my ($ix,$iy) = @_; printf TTY "\e[%d;%dH",$iy+1,$ix+1; }

my $InitscrAlreadyRun = 0;
my $IsMouseMode  = 0;
my $WasMouseMode = 0;
my $IsSpeakUpSilent  = 0;  # 1.62
my $WasSpeakUpSilent = 0;  # 1.62
my $Stty = q{};

sub enter_mouse_mode {   # 1.50
	if ($ENV{'CLUI_MOUSE'} eq 'OFF') { return 0; }   # 1.62
	if ($IsMouseMode) {
		warn "enter_mouse_mode but already IsMouseMode\r\n"; return 1 ;
	}
	if ($EncodingString) {
		close TTYIN;
		open(TTYIN, "<:bytes", '/dev/tty')
			 || (warn "Can't read /dev/tty: $!\n", return 0);
	}
	print TTY "\e[?1003h";   # sets   SET_ANY_EVENT_MOUSE  mode
	$IsMouseMode = 1;
	return 1;
}
sub leave_mouse_mode {   # 1.50
	# if ($ENV{'CLUI_MOUSE'} =~ /off/i) { return 0; }   # 1.62
	if (!$IsMouseMode) {
		warn "leave_mouse_mode but not IsMouseMode\r\n"; return 1 ;
	}
	if ($EncodingString) {
		close TTYIN;
		open(TTYIN, "<$EncodingString", '/dev/tty')
 		 || (warn "Can't read /dev/tty: $!\n", return 0);
	}
	print TTY "\e[?1003l";   # cancels SET_ANY_EVENT_MOUSE mode
	$IsMouseMode = 0;
	return 1;
}

sub enter_speakup_silent {   # 1.62
	# echo 7 > /sys/accessibility/speakup/silent  if it exists
	if (!$SpeakUpSilentFile) { return 0; }
	if ($IsSpeakUpSilent) {
		warn "enter_speakup_silent but already IsSpeakUpSilent\r\n"; return 1 ;
	}
	if (open(S, '>', $SpeakUpSilentFile)) { print S "7\n"; close S; }
	$IsSpeakUpSilent = 1;
	return 1;
}
sub leave_speakup_silent {   # 1.62
	# echo 4 > /sys/accessibility/speakup/silent  if it exists
	if (!$SpeakUpSilentFile) { return 0; }
	if (!$IsSpeakUpSilent) {
		warn "leave_speakup_silent but not IsSpeakUpSilent\r\n"; return 1 ;
	}
	if (open(S, '>', $SpeakUpSilentFile)) { print S "4\n"; close S; }
	$IsSpeakUpSilent = 0;
	return 1;
}

sub initscr { my %args = @_;
	my $mouse_mode = $args{'mouse_mode'};          # for mouse-handling
	if ($ENV{'CLUI_MOUSE'} eq 'OFF') { $mouse_mode = undef; }  # 1.62
	my $speakup_silent = $args{'speakup_silent'};  # to silence SpeakUp
	if ($InitscrAlreadyRun) {
		$InitscrAlreadyRun++;
		if (!$mouse_mode and $IsMouseMode) {
			leave_mouse_mode() or return 0;
		} elsif ($mouse_mode and !$IsMouseMode) {
			enter_mouse_mode() or return 0;
		}
		$WasMouseMode = $IsMouseMode;
		if (!$speakup_silent and $IsSpeakUpSilent) {   # 1.62
			leave_speakup_silent() or return 0;
		} elsif ($speakup_silent and !$IsSpeakUpSilent) {
			enter_speakup_silent() or return 0;
		}
		$WasSpeakUpSilent = $IsSpeakUpSilent;
		$icol = 0; $irow = 0;
		return;
	}
	open(TTY, ">$EncodingString", '/dev/tty')   # 1.43
	 || (warn "Can't write /dev/tty: $!\n", return 0);
	if (!$have_Term_ReadKey) { $Stty = `stty -g`; chop $Stty; }
	my $encoding_string;
	if ($mouse_mode) {
		$IsMouseMode = 1; $encoding_string = ':bytes';
		print TTY "\e[?1003h";   # sets  SET_ANY_EVENT_MOUSE  mode
	} else {
		$IsMouseMode = 0; $encoding_string = $EncodingString;
	}
	if ($speakup_silent and !$IsSpeakUpSilent) { enter_speakup_silent(); }
	open(TTYIN, "<$encoding_string", '/dev/tty')
	 || (warn "Can't read /dev/tty: $!\n", return 0);

	if ($have_Term_ReadKey) {
		Term::ReadKey::ReadMode('ultra-raw', *TTYIN);
	} else {
		if ($^O =~ /^FreeBSD$/i) { system("stty -echo -icrnl raw </dev/tty");
		} else { system("stty -echo -icrnl raw </dev/tty >/dev/tty");
		}
	}
	select((select(TTY), $| = 1)[0]); print TTY q{};
	$rin = q{}; vec($rin, fileno(TTYIN), 1) = 1;
	$icol = 0; $irow = 0; $InitscrAlreadyRun = 1;
}

sub endwin {
	print TTY "\e[0m";
	if ($InitscrAlreadyRun > 1) {
		if      ($IsMouseMode and !$WasMouseMode) { leave_mouse_mode();
		} elsif (!$IsMouseMode and $WasMouseMode) { enter_mouse_mode();
		}
		if      ($IsSpeakUpSilent and !$WasSpeakUpSilent) {   # 1.62
			leave_speakup_silent();
		} elsif (!$IsSpeakUpSilent and $WasSpeakUpSilent) {
			enter_speakup_silent();
		}
		$InitscrAlreadyRun--; return;
	}
	print TTY "\e[?1003l";   $IsMouseMode = 0;
	if ($IsSpeakUpSilent) { leave_speakup_silent(); }
	if ($have_Term_ReadKey) {
		Term::ReadKey::ReadMode('restore', *TTYIN);
		close TTY; close TTYIN;
	} else {
		close TTY; close TTYIN;
		if ($^O =~ /^FreeBSD$/i) { system("stty $Stty </dev/tty") if $Stty;
		} else { system("stty $Stty </dev/tty >/dev/tty") if $Stty;
		}
	}
	$InitscrAlreadyRun = 0;
}

# ----------------------- size handling ----------------------

my ($maxcols, $maxrows); my $size_changed = 1;
my @OtherLines;  # 20131002 $otherlines, $notherlines no longer global

sub check_size {
	if (! $size_changed) { return; }
	if ($have_Term_ReadKey) {
		($maxcols, $maxrows) = Term::ReadKey::GetTerminalSize(*STDERR);
	} elsif ($have_Term_Size) {
		($maxcols, $maxrows) = Term::Size::chars(*STDERR);
	} else {
		$maxcols = `tput cols`;
		$maxrows = (`tput lines` + 0) || (`tput rows` + 0);
	}
	$maxcols = $maxcols || 80; $maxcols--;
	$maxrows = $maxrows || 24;
	if (@OtherLines) {
		@OtherLines = &fmt(join("\n",@OtherLines));
	}
	$size_changed = 0;
}
$SIG{'WINCH'} = sub { $size_changed = 1; };

# ------------------------ ask stuff -------------------------

# Options such as integer, real, positive, >x, >=x, <x <=x,
# non-null, max-length, min-length, silent  ...
# default could be just one more option, and backward compatibilty
# could be preserved by checking whether the 2nd arg is a hashref ...

sub ask_filename { my ($question, $default) = @_;  # 1.65 tab-completion
	eval 'require Term::ReadLine'; if ($@) {
		sorry("you should install Term::ReadLine::Gnu from www.cpan.org");
		return ask($question, $default);
	}
	initscr(speakup_silent=>1);
	endwin();
	$term = new Term::ReadLine 'ProgramName';
	my $filename = $term->readline($question.' ');   # 1.70
	print STDERR "\e[J";
	$filename =~ s/ $//;   # 1.66
	return $filename;
}
sub ask_password { # no echo - use for passwords
	local ($silent) = 'yes'; &ask($_[0]);
}
sub ask { my ($question, $default) = @_;
	return q{} unless $question;
	&initscr(speakup_silent=>1);
	my $nol = &display_question($question);

	my $i = 0; my $n = 0; my @s = (); # cursor position, length, string
	if (defined $default) {  # 1.69 defined, to include 0
		&speak("$question, default is $default");
		$default =~ s/\t/	/g;
		@s = split(q{}, $default); $n = scalar @s; $i = 0;
		foreach $j (0 .. $#s) { &puts($s[$j]); }
		&left($n);
	} else {
		&speak($question);
	}

	while (1) {
		my $c = &getch();
		if ($c eq "\r") { &erase_lines(1); last; }
		if ($size_changed) {
			&erase_lines(0); $nol = &display_question($question);
		}
		if ($c == $KEY_LEFT) {
			if ($i > 0) { $i--; &left(1); }  # 1.44
		} elsif ($c == $KEY_RIGHT) {
			if ($i < $n) { &puts($silent ? "x" : $s[$i]); $i++; }
		} elsif ($c == $KEY_DELETE) {  # 1.54
			if ($i < $n) {
			 	$n--; splice(@s, $i, 1);
			  	foreach $j ($i..$#s) { &puts($silent ? "x" : $s[$j]); } # 1.67
			  	&clrtoeol(); &left($n-$i);
			}
		} elsif (($c eq "\cH") || ($c eq "\c?")) {
			if ($i > 0) {
			 	$n--; $i--;
				if (! $silent) { &speak($s[$i]); }   # 1.63
				splice(@s, $i, 1); &left(1);
			  	foreach $j ($i..$#s) { &puts($silent ? "x" : $s[$j]); } # 1.67
			  	&clrtoeol(); &left($n-$i);
			}
		} elsif ($c eq "\cC") {  # 1.56
			&erase_lines(1); &endwin();
			warn "^C\n"; kill('INT', $$); return undef;
		} elsif ($c eq "\cX" || $c eq "\cD") {  # clear ...
			&left($i); $i = 0; $n = 0; &clrtoeol(); @s = ();
		} elsif ($c eq "\cA" || $c == $KEY_HOME) { &left($i); $i = 0;
		} elsif ($c eq "\cE" || $c == $KEY_END)  { &right($n-$i); $i = $n;
		} elsif ($c eq "\cL") { &speak(join("", @s));  # redraw ...
		} elsif ($SpecialKey{$c}) { &beep();
		} elsif (ord($c) >= 32) {  # 1.51
			splice(@s, $i, 0, $c);
			&puts($silent ? "x" : $c);
			if (! $silent) {  &speak($c); }
			$n++; $i++;
			foreach $j ($i..$#s) { &puts($silent ? "x" : $s[$j]); }  # 1.67
			&clrtoeol();  &left($n-$i);
		} else { &beep();
		}
	}
	&speak(join("", @s), 'wait');
	&endwin(); $silent = q{}; return join("", @s);
}

# ----------------------- choose stuff -------------------------
sub debug {
	if (! open (DEBUG, '>>/tmp/clui.log')) {
		warn "can't open /tmp/clui.log: $!\n"; return;
	}
	print DEBUG "$_[0]\n"; close DEBUG;
}

my (%irow, %icol, $nrows, $clue_has_been_given, $choice, $this_cell);
my @marked;
my $HOME = $ENV{'HOME'} || $ENV{'LOGDIR'} || (getpwuid($<))[7];
srand(time() ^ ($$+($$<15)));

sub choose {  my $question = shift; local @list = @_;  # @list must be local
	# As from 1.22, allows multiple choice if called in array context

	return unless @list;
	grep (($_ =~ s/[\r\n]+$//) && 0, @list);	# chop final newlines
	my @biglist = @list; my $icell; @marked = ();

	$question =~ s/^[\n\r]+//;   # strip initial newline(s)
	$question =~ s/[\n\r]+$//;   # strip final newline(s)
	my ($firstline,$otherlines) = split(/\r?\n/, $question, 2);
	my $firstlinelength = length $firstline;

	$choice = &get_default($firstline);
	# If wantarray ? Is remembering multiple choices safe ?

	&initscr(mouse_mode=>1, speakup_silent=>1);
	&size_and_layout(0);
	@OtherLines = &fmt($otherlines);
	my $speaktext = join(' ',$list[$this_cell],'. ',@OtherLines);
	if (wantarray) {
		$#marked = $#list;
		if ($firstlinelength < $maxcols-30) {
			&puts("$firstline (multiple choice with spacebar)\n\r");
		} elsif ($firstlinelength < $maxcols-16) {
			&puts("$firstline (multiple choice)\n\r");
		} elsif ($firstlinelength < $maxcols-9) {
			&puts("$firstline (multiple)\n\r");
		} else {
			&puts("$firstline\n\r");
		}
		if ($nrows >= $maxrows) { &speak("$firstline, ", 'wait');
		} else { &speak("$firstline, multiple choice, $speaktext");
		}
	} else {
		&puts("$firstline\n\r");
		if ($nrows >= $maxrows) { &speak("$firstline, ", 'wait');
		} else { &speak("$firstline, choose, $speaktext");
		}
	}
	if ($nrows >= $maxrows) {
		@list = &narrow_the_search(@list);
		if (! @list) {
			&up(1); &clrtoeol(); &endwin(); $clue_has_been_given = 0;
			return wantarray ? () : undef;
		}
		my $speaktext = join(' ',$list[$this_cell],'. ',@OtherLines);
		&speak("choose, $speaktext");
	}
	&wr_screen();
	# the cursor is now on this_cell, not on the question
	print TTY "\e[6n";  # terminfo u7, will set $AbsCursX,$AbsCursY
	$CursorRow = $irow[$this_cell];  # global, needed by handle_mouse

	while (1) {
		$c = &getch();
		if ($size_changed) {
			&size_and_layout($nrows);
			if ($nrows >= $maxrows) {
				@list = &narrow_the_search(@list);
				if (! @list) {
					&up(1); &clrtoeol(); &endwin(); $clue_has_been_given = 0;
					return wantarray ? () : undef;
				}
			}
			&wr_screen();
			&speak("choose, $list[$this_cell]");
		}
		if ($c eq "q" || $c eq "\cD" || $c eq "\cX") {
			&erase_lines(1);
			if ($clue_has_been_given) {
				my $re_clue = &confirm("Do you want to change your clue ?");
				&up(1); &clrtoeol();   # erase the confirm
				if ($re_clue) {
					$irow = 1;
					@list = &narrow_the_search(@biglist); &wr_screen();
					&speak("choose, $list[$this_cell]");
					next;
				} else {
					&up(1); &clrtoeol(); &endwin(); $clue_has_been_given = 0;
					return wantarray ? () : undef;
				}
			}
			&goto(0,0); &clrtoeol(); &endwin(); $clue_has_been_given = 0;
			return wantarray ? () : undef;
		} elsif (($c eq "\t") && ($this_cell < $#list)) {
			$this_cell++; &wr_cell($this_cell-1); &wr_cell($this_cell); 
			&speak($list[$this_cell]);
		} elsif ((($c eq "l") || ($c == $KEY_RIGHT)) && ($this_cell < $#list)
			&& ($irow[$this_cell] == $irow[$this_cell+1])) {
			$this_cell++; &wr_cell($this_cell-1); &wr_cell($this_cell); 
			&speak($list[$this_cell]);
		} elsif ((($c eq "\cH") || ($c == $KEY_BTAB)) && ($this_cell > 0)) {
			$this_cell--; &wr_cell($this_cell+1); &wr_cell($this_cell); 
			&speak($list[$this_cell]);
		} elsif ((($c eq "h") || ($c == $KEY_LEFT)) && ($this_cell > 0)
			&& ($irow[$this_cell] == $irow[$this_cell-1])) {
			$this_cell--; &wr_cell($this_cell+1); &wr_cell($this_cell); 
			&speak($list[$this_cell]);
		} elsif ((($c eq "j") || ($c == $KEY_DOWN)) && ($irow < $nrows)) {
			my $mid_col = $icol[$this_cell] + 0.5 * length($list[$this_cell]);
			my $left_of_target = 1000;
			for ($inew=$this_cell+1; $inew < $#list; $inew++) {
				last if $icol[$inew] < $mid_col;	# skip rest of row
			}
			my $new_mid_col = 0;
			for (; $inew < $#list; $inew++) {
				$new_mid_col = $icol[$inew] + 0.5*length($list[$inew]);
				last if $new_mid_col >= $mid_col;		# we've reached it
				last if $icol[$inew+1] <= $icol[$inew]; # we're at EOL
				$left_of_target = $mid_col - $new_mid_col;
			}
			if (($new_mid_col - $mid_col) > $left_of_target) { $inew--; }
			$iold = $this_cell; $this_cell = $inew;
			&wr_cell($iold); &wr_cell($this_cell);
			&speak($list[$this_cell]);
		} elsif ((($c eq "k") || ($c == $KEY_UP)) && ($irow > 1)) {
			my $mid_col = $icol[$this_cell] + 0.5*length($list[$this_cell]);
			my $right_of_target = 1000;
			for ($inew=$this_cell-1; $inew > 0; $inew--) {
				last if $irow[$inew] < $irow[$this_cell];	# skip rest of row
			}
			my $new_mid_col = 0;
			for (; $inew > 0; $inew--) {
				last unless $icol[$inew];
				$new_mid_col = $icol[$inew] + 0.5*length($list[$inew]);
				last if $new_mid_col <= $mid_col;		 # we're past it
				$right_of_target = $new_mid_col - $mid_col;
			}
			if (($mid_col - $new_mid_col) > $right_of_target) { $inew++; }
			$iold = $this_cell; $this_cell = $inew;
			&wr_cell($iold); &wr_cell($this_cell);
			&speak($list[$this_cell]);
		} elsif ($c eq "\cL") {
			if ($size_changed) {
				&size_and_layout($nrows);
				if ($nrows >= $maxrows) {
					@list = &narrow_the_search(@list);
					if (! @list) {
						&up(1); &clrtoeol(); &endwin();
						$clue_has_been_given = 0;
						return wantarray ? () : undef;
					}
				}
			}
			&wr_screen();
		} elsif ($c eq "\cC") {  # 1.56
			&erase_lines(1); &endwin();
			warn "^C\n"; kill('INT', $$); return undef;
		} elsif ($c eq "\r") {
			&erase_lines(1); &goto($firstlinelength+1, 0);
			my @chosen;
			if (wantarray) {
				my $i; for ($i=0; $i<=$#list; $i++) {
					if ($marked[$i] || $i==$this_cell) {
						push @chosen, $list[$i];
					}
				}
				&clrtoeol();
				my $remaining = $maxcols-$firstlinelength;
				my $last = pop @chosen;
				my $dotsprinted;
				foreach (@chosen) {
					if (($remaining - length $_) < 4) {
						$dotsprinted=1; &puts("..."); $remaining -= 3; last;
					} else {
						&puts("$_, "); $remaining -= (2 + length $_);
					}
				}
				if (!$dotsprinted) {
					if (($remaining - length $last)>0) { &puts($last);
					} elsif ($remaining > 2) { &puts('...');
					}
				}
				&puts("\n\r");
				push @chosen, $last;
			} else {
				&puts($list[$this_cell]."\n\r");
			}
			&endwin();
			&set_default($firstline, $list[$this_cell]); # join($,,@chosen) ?
			$clue_has_been_given = 0;
			if (wantarray) {
				&speak(join(' and ',@chosen), 'wait'); return @chosen;
			} else {
				&speak($list[$this_cell], 'wait'); return $list[$this_cell];
			}
		} elsif ($c eq " ") {
			if (wantarray) {
				$marked[$this_cell] = !$marked[$this_cell];
				#if ($this_cell < $#list) {
					#  $this_cell++; &wr_cell($this_cell-1); # 1.50
				&wr_cell($this_cell); 
				&speak('marked');
				#}
			#} elsif ($this_cell < $#list) {
			#	$this_cell++; &wr_cell($this_cell-1); &wr_cell($this_cell); 
			}
		} elsif ($c eq "?") {
			warn "help\r\n";
		}
	}
	&endwin();
	warn "choose: shouldn't reach here ...\n";
}
sub layout { my @list = @_;
	$this_cell = 0; my $irow = 1; my $icol = 0;  my $i;
	for ($i=0; $i<=$#list; $i++) {
		$l[$i] = length($list[$i]) + 2;
		if ($l[$i] > $maxcols-1) { $l[$i] = $maxcols-1; }  # 1.42
		if (($icol + $l[$i]) >= $maxcols ) { $irow++; $icol = 0; }
		if ($irow > $maxrows) { return $irow; }  # save time
		$irow[$i] = $irow; $icol[$i] = $icol;
		$icol += $l[$i];
		if ($list[$i] eq $choice) { $this_cell = $i; }
	}
	return $irow;
}
sub wr_screen {
	for (my $i=0; $i<=$#list; $i++) {
		&wr_cell($i) unless $i==$this_cell;
	}
	my $notherlines = scalar @OtherLines;
	if ($notherlines && ($nrows+$notherlines) < $maxrows) {
		&puts("\r\n", join("\r\n", @OtherLines), "\r");
	}
	&wr_cell($this_cell);
}
sub wr_cell { my $i = shift;
	my $no_tabs = $list[$i];
	$no_tabs =~ s/\t/ /g;
	&goto($icol[$i], $irow[$i]);
	if ($marked[$i]) { &attrset($A_BOLD | $A_UNDERLINE); }
	if ($i == $this_cell) { &attrset($A_REVERSE); }
	&puts(substr " $no_tabs ", 0, $maxcols);  # 1.42, 1.54
	if ($marked[$i] || $i == $this_cell) { &attrset($A_NORMAL); }
}
sub size_and_layout {
	my $erase_rows = shift;
	&check_size();
	if ($erase_rows) {
		if ($erase_rows > $maxrows) { $erase_rows = $maxrows; } # XXX?
		&erase_lines(1);
	}
	$nrows = &layout(@list);
}
sub narrow_the_search { my @biglist = @_;
	# replaces the old ... require 'complete.pl';
	# return &Complete("$firstline (TAB to complete, ^D to list) ", @list);
	my $nchoices = scalar @_;
	my $n; my $i; my @s; my $s; my @list = @biglist;
	$clue_has_been_given = 1;
	if ($IsMouseMode) { leave_mouse_mode(); }
	&ask_for_clue($nchoices, $i, $s);
	while (1) {
		$c = &getch();
		if ($size_changed) {
			&size_and_layout(0);
			if ($nrows < $maxrows) {
				&erase_lines(1); enter_mouse_mode(); return @list;
			}
		}
		if ($c == $KEY_LEFT && $i > 0) { $i--; &left(1); next;
		} elsif ($c == $KEY_RIGHT) {
			if ($i < $n) { &puts($s[$i]); $i++; next; }
		} elsif (($c eq "\cH") || ($c eq "\c?")) {
			if ($i > 0) {
			 	$n--; $i--;
				&speak($s[$i], 'wait');   # 1.63
				splice(@s, $i, 1); &left(1);
			  	foreach $j ($i..$n) { &puts($s[$j]); }
				&clrtoeol(); &left($n-$i);
			}
		} elsif ($c eq "\cC") {  # 1.56
			&erase_lines(1); &endwin();
			warn "^C\n"; kill('INT', $$); return undef;
		} elsif ($c eq "\cX" || $c eq "\cD") {  # clear ...
			if (! @s) {   # 20070305 ?
				$clue_has_been_given = 0; &erase_lines(1); 
				enter_mouse_mode(); return ();
			}
			&left($i); $i = 0; $n = 0; @s = (); &clrtoeol();
		} elsif ($c eq "\cA") { &left($i); $i = 0; next;
		} elsif ($c eq "\cE") { &right($n-$i); $i = $n; next;
		} elsif ($c eq "\cL") {
		} elsif ($SpecialKey{$c}) { &beep();
		} elsif (ord($c) >= 32) {  # 1.51
			splice(@s, $i, 0, $c);
			$n++; $i++; &puts($c);
			foreach $j ($i..$n) { &puts($s[$j]); } &clrtoeol();  &left($n-$i);
			&speak($c, 'wait');   # 1.63
		} else { &beep();
		}
		# grep, and if $nchoices=1 return
		$s = join("", @s);
		@list = grep(0 <= index($_,$s), @biglist);
		$nchoices = scalar @list;
		$nrows = &layout(@list);
		if ($nchoices==1 || ($nchoices && ($nrows<$maxrows))) {
			&puts("\r"); &clrtoeol(); &up(1); &clrtoeol();
			enter_mouse_mode(); return @list;
		}
		&ask_for_clue($nchoices, $i, $s);
	}
	warn "narrow_the_search: shouldn't reach here ...\n";
}
sub ask_for_clue { my ($nchoices, $i, $s) = @_;
	if ($nchoices) {
		if ($s) {
			my $headstr = "the choices won't fit; there are still";
			&goto(0,1); &puts("$headstr $nchoices of them"); &clrtoeol();
			&goto(0,2); &puts("lengthen the clue : "); &right($i);
			&speak("still $nchoices choices, lengthen the clue");
		} else {
			my $headstr = "the choices won't fit; there are";
			&goto(0,1); &puts("$headstr $nchoices of them"); &clrtoeol();
			&goto(0,2);
			&puts("   give me a clue :             (or ctrl-X to quit)");
			&left(31);   # 1.62
			&speak("$nchoices choices, give me a clue, or control-X to quit");
		}
	} else {
		&goto(0,1); &puts("No choices fit this clue !"); &clrtoeol();
		&goto(0,2); &puts(" shorten the clue : "); &right($i);
		&speak("no choices fit, shorten the clue");
	}
}
sub get_default { my ($question) = @_;
	if ($ENV{CLUI_DIR} =~ /off/i) { return undef; }
	if (! $question) { return undef; }
	my @choices;
	my $n_tries = 5;
	while ($n_tries--) {
		if (dbmopen (%CHOICES, &dbm_file(), 0600)) {
			last;
		} else { 
			if ($! eq 'Resource temporarily unavailable') {
				my $wait = rand 0.45; select undef, undef, undef, $wait;
			} else { return undef;
			}
		}
	}
	@choices = split ($; ,$CHOICES{$question}); dbmclose %CHOICES;
	if (wantarray) { return @choices;
	} else { return $choices[0];
	}
}
sub set_default { my $question = shift; my $s = join($; , @_);
	if ($ENV{CLUI_DIR} =~ /off/i) { return undef; }
	if (! $question) { return undef; }
	my $n_tries = 5;
	while ($n_tries--) {
		if (dbmopen(%CHOICES, &dbm_file(), 0600)) {
			last;
		} else { 
			if ($! eq 'Resource temporarily unavailable') {
				my $wait = rand 0.50; select undef, undef, undef, $wait;
			} else { return undef;
			}
		}
	}
	$CHOICES{$question} = $s; dbmclose %CHOICES;
	return $s;
}
sub dbm_file {
	if ($ENV{CLUI_DIR} =~ /off/i) { return undef; }
	my $db_dir;
	if ($ENV{CLUI_DIR}) {
		$db_dir = $ENV{CLUI_DIR};
		$db_dir =~ s#^~/#$HOME/#;
	} else { $db_dir = "$HOME/.clui_dir";
	}
	mkdir ($db_dir,0750);
	return "$db_dir/choices";
}
sub handle_mouse { my ($x, $y, $button_pressed, $button_drag) = @_;  # 1.50 
	$TopRow = $AbsCursY - $CursorRow;
	if ($LastEventWasPress) { $LastEventWasPress = 0; return(''); }
	return('') unless $y >= $TopRow;
	my $mouse_row = $y - $TopRow;
	my $mouse_col = $x - 1;
	# debug("x=$x y=$y TopRow=$TopRow mouse_row=$mouse_row");
	# debug("button_pressed=$button_pressed button_drag=$button_drag");
	my $found = 0;
	my $i = 0; while ($i < @irow) {
		if ($irow[$i] == $mouse_row) {
			# debug("list[$i]=$list[$i] is the right row");
			if ($icol[$i] < $mouse_col
			 and ($icol[$i]+length($list[$i]) >= $mouse_col)) {
				$found = 1; last;
			}
			last if $irow[$i] > $mouse_row;
		}
		$i += 1;
	}
	return unless $found;
	# if xterm doesn't receive a button-up event it thinks it's dragging
	my $return_char = q{};
	if ($button_pressed == 1 and !$button_drag) {
		$LastEventWasPress = 1;
		$return_char = $KEY_ENTER;
	} elsif ($button_pressed == 3 and !$button_drag) {
		$LastEventWasPress = 1;
		$return_char = q{ };
	}
	if ($i != $this_cell) {
		my $t = $this_cell; $this_cell = $i;
		&wr_cell($t); &wr_cell($this_cell); 
	}
	return $return_char;
}
sub help_text { # 1.54
	my $text;
	if ($_[0] eq 'ask') {
		return "\nLeft and Right arrowkeys, Backspace, Delete; control-A = "
		 . " beginning; control-E = end; control-X = clear; then Return.";
	}
	if ($ENV{'CLUI_MOUSE'} eq 'OFF') {
		$text = "\nmove around with Arrowkeys (or hjkl);";
	} else {
		$text = "\nmove around with Mouse or Arrowkeys (or hjkl);";
	}
	if ($_[0] =~ /^mult/) {
		$text .= " multiselect with Rightclick or Spacebar;";
	}
	$text .= " then either q or ctrl-X for quit,";
	if ($ENV{'CLUI_MOUSE'} eq 'OFF') {
		$text .= " or Return to choose.";
	} else {
		$text .= " or choose with Leftclick or Return.";
	}
}

# ----------------------- confirm stuff -------------------------

sub confirm { my $question = shift;  # asks user Yes|No, returns 1|0
	return(0) unless $question;  return(0) unless -t STDERR;
	&initscr(speakup_silent=>1);
	my $nol = &display_question($question); &puts(" (y/n) ");
	&speak($question . ', y or n');
	while (1) {
		$response=&getch();
		if ($response eq "\cC") {  # 1.56
			&erase_lines(1); &endwin();
			warn "^C\n"; kill('INT', $$); return undef;
		}
		last if ($response=~/[yYnN]/);
		&beep();
	}
	&left(6); &clrtoeol(); 
	if ($response=~/^[yY]/) {
		&puts("Yes");
		&speak('yess', 'wait');
	} else {
		&puts("No");
		&speak('know', 'wait');
	}
	&erase_lines(1); &endwin();
	if ($response =~ /^[yY]/) { return 1; } else { return 0 ; }
}

# ----------------------- edit stuff -------------------------

sub edit {	my ($title, $text) = @_;
	my $argc = $#_ - 0 +1;
	my ($dirname, $basename, $rcsdir, $rcsfile, $rcs_ok);
	
	if ($argc == 0) {	# start editor session with no preloaded file
		system $ENV{EDITOR} || "vi"; # should also look in ~/db/choices.db
	} elsif ($argc == 2) {
		# must create tmp file with title embedded in name
		my $tmpdir = '/tmp';
		my $safename = $title;
		$safename =~ s/[\W_]+/_/g;
		my $file = "$tmpdir/$safename.$$";
		if (!open(F,">$file")) {&sorry("can't open $file: $!\n");return q{};}
		print F $text; close F;
		$editor = $ENV{EDITOR} || "vi"; # should also look in ~/db/choices.db
		system "$editor $file";
		if (!open(F,"< $file")) {&sorry("can't open $file: $!\n");return 0;}
		undef $/; $text = <F>; $/ = "\n";
		close F; unlink $file; return $text;
	} elsif ($argc == 1) {	# its a file, we will try RCS ...
		my $file = $title;

		# weed out no-go situations
		if (-d $file) {&sorry("$file is already a directory\n"); return 0;}
		if (-B _ && -s _) {&sorry("$file is not a text file\n"); return 0;}
		if (-T _ && !-w _) { &view($file); return 1; }
	
		# it's a writeable text file, so work out the locations
		if ($file =~ /\//) {
			($dirname, $basename) = $file =~ /^(.*)\/([^\/]+)$/;
			$rcsdir  = "$dirname/RCS";
			$rcsfile = "$rcsdir/$basename,v";
		} else {
			$basename = $file;
			$rcsdir  = "RCS";
			$rcsfile = "$rcsdir/$basename,v";
		}
		$rcslog = "$rcsdir/log";
	
		# we no longer create the RCS directory if it doesn't exist,
		# so `mkdir RCS' to enable rcs in a directory ...
		$rcs_ok = 1;	if (!-d $rcsdir) { $rcs_ok = 0; }
		if (-d _ && ! -w _) { $rcs_ok = 0;	warn "can't write in $rcsdir\n"; }
	
		# if the file doesn't exist, but the RCS does, then check it out
		if ($rcs_ok && -f $rcsfile && !-f $file) {
			system "co -l $file $rcsfile";
		}

		my $starttime = time;
		$editor = $ENV{EDITOR} || "vi"; # should also look in ~/db/choices.db
		system "$editor $file";
		my $elapsedtime = time - $starttime;
		# could be output or logged, for worktime accounting
	
		if ($rcs_ok && -T $file) {	 # check it in
			if (!-f $rcsfile) {
				my $msg = &ask("$file is new. Please describe it:");
				my $quotedmsg = $msg;  $quotedmsg =~ s/'/'"'"'/g;
				if ($msg) {
					system "ci -q -l -t-'$quotedmsg' -i $file $rcsfile";
					&logit($basename, $msg);
				}
			} else {
				my $msg = &ask("What changes have you made to $file ?");
				my $quotedmsg = $msg;  $quotedmsg =~ s/'/'"'"'/g;
				if ($msg) {
					system "ci -q -l -m'$quotedmsg' $file $rcsfile";
					&logit($basename, $msg);
				}
			}
		}
	}
}
sub logit { my ($file, $msg) = @_;
	if (! open(LOG, ">> $rcslog")) {  warn "can't open $rcslog: $!\n";
	} else {
		$pid = fork;	# log in background for better response time
		if (! $pid) {
			($user) = getpwuid($>);
			print LOG &timestamp, " $file $user $msg\n"; close LOG;
			if ($pid == 0) { exit 0; }	# the child's end, if a fork occurred
		}
	}
}
sub timestamp {
	# returns current date and time in "199403011 113520" format
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
	$wday += 0; $yday += 0; $isdst += 0; # avoid bloody -w warning
	return sprintf("%4.4d%2.2d%2.2d %2.2d%2.2d%2.2d",
		$year+1900, $mon+1, $mday, $hour, $min, $sec);
}

# ----------------------- sorry stuff -------------------------

sub sorry { # warns user of an error condition
	print STDERR "Sorry, $_[0]\n";
	&speak("Sorry, $_[0]", 'wait');
}
sub inform { my $text = $_[0];
	$text =~ s/([^\n])$/$1\n/s;
	if (open(TTY, ">$EncodingString", '/dev/tty')) {  # 1.43
		print TTY $text; close TTY;
	} else { warn $text;
	}
	&speak($text, 'wait');
}

# ----------------------- view stuff -------------------------

foreach $f ("/usr/bin/less", "/usr/bin/more") {
	if (-x $f) { $default_pager = $f; }
}
sub view {	my ($title, $text) = @_;	# or ($filename) =
	my $pager = $ENV{PAGER} || $default_pager;
	if (! $text and ($title =~ /\.doc$/i) and -r $title) {   # 1.65
		my $wvText = which('wvText');   if ($wvText) {
			my $tmpf = "/tmp/wv$$";
			system "$wvText '$title' $tmpf"; system "$pager $tmpf";
			unlink $tmpf; return 1;
		}
		my $antiword = which('antiword');   if ($antiword) {
			system "$antiword -i 1 '$title' | $pager"; return 1;
		}
		my $catdoc = which('catdoc');   if ($catdoc) {
			system "$catdoc '$title' | $pager"; return 1;
		}
		sorry("it's a .doc file; you need to install wv, antiword or catdoc");
		return 0;
	} elsif (! $text && -T $title && open(F,"< $title")) {
		$nlines = 0;
		while (<F>) { last if ($nlines++ > $maxrows); } close F;
		if ($nlines > (0.6*$maxrows)) {
			system "$pager  \'$title\'";
		} else {
			open(F,"< $title"); undef $/; $text=<F>; $/="\n"; close F;
			&tiview($title, $text);
		}
	} else {
		local (@lines) = split(/\r?\n/, $text, $maxrows);
		if (($#lines) < 21) {
			&tiview($title, $text);
		} else {
			local ($safetitle); ($safetitle = $title) =~ s/[^a-zA-Z0-9]+/_/g;
			local ($tmp) = "/tmp/$safetitle.$$";
			if (!open(TMP, ">$tmp")) {warn "can't open $tmp: $!\n"; return;}
			print TMP $text;	close TMP;
			system "$pager \'$tmp\'";
			unlink $tmp;
			return 1;
		}
	}
}
sub tiview {	my ($title, $text) = @_;
	return unless $text;
	$title =~ s/\t/ /g; my $titlelength = length $title;
	
	&check_size();
	my @rows = &fmt($text, nofill=>1);
	&initscr();
	if (3 > scalar @rows) {
		&puts("$title\r\n".join("\r\n",@rows), "\r\n");
		&speak("$title, ".join(" ",@rows), 'wait');
		&endwin(); return 1;
	}
	if ($titlelength > ($maxcols-35)) { &puts("$title\r\n");
	} else { &puts("$title   (<enter> to continue, q to clear)\r\n");
	}
	&puts("\r", join("\e[K\r\n",@rows), "\r");
	&speak("$title, enter to continue, ".join(" ",@rows));
	$icol = 0; $irow = scalar @rows; &goto($titlelength+1, 0);
	
	while (1) {
		$c = &getch();
		if ($c eq 'q' || $c eq "\cX" || $c eq "\cW" || $c eq "\cZ"
		|| $c eq "\cC" || $c eq "\c\\") {
			&erase_lines(0); &endwin(); return 1;
		} elsif ($c eq "\r") {  # <enter> retains text on screen
			&clrtoeol(); &goto(0, @rows+1); &endwin(); return 1;
		} elsif ($c eq "\cL") {
			&puts("\r"); &endwin(); &tiview($title,$text); return 1;
		}
	}
	warn "tiview: shouldn't reach here\n";
}

# -------------------------- infrastructure -------------------------

sub which {
	my $f;
	foreach $d (split(":",$ENV{'PATH'})) {$f="$d/$_[0]"; return $f if -x $f;}
}
%SpeakMode = ();
sub END {
	if ($Eflite_FH) { print $Eflite_FH "s\nq { }\n"; close $Eflite_FH;
	} elsif ($Espeak_PID) { kill SIGHUP, $Espeak_PID; wait;
	}
}
sub speak {  my ($text, $wait) = @_;
	$text="$text";
	return unless length($text);  # should clean up for exit: kill or wait
	# could replace the punctuation chars with descriptive words...
	if ($SpeakMode{'dot'}) {
		$text =~ s/\s*\.\s*/ dot /g;
		$text =~ s/\s*\.(\w)/ dot $1/g;
	}
	if ($Eflite_FH) {
		if (length($text) == 1) {
			if ($text eq '.') { print $Eflite_FH "s\nq { dot }\nd\n";
			} else { print $Eflite_FH "s\nl {$text}\n";
			}
			if ($wait) { select(undef,undef,undef,0.5); }
		} else {
			print $Eflite_FH "s\nq {$text}\nd\n";
			# useless emacspeak op: tts_sy nc_state all 0 0  1 225\nq {[:np  ]}
			if ($wait) { select(undef,undef,undef,0.3+0.07*length($text)); }
		}
	} elsif ($Espeak) {  # 1.68 should be using Speech::eSpeak !
		if ($Espeak_PID) { kill SIGHUP, $Espeak_PID; wait; $Espeak_PID = 0; }
		$Espeak_PID = fork();
		if ($Espeak_PID) {
			if ($wait) {
				if (length($text) == 1) { select(undef,undef,undef,0.5);
				} else { select(undef,undef,undef,0.3+0.07*length($text));
				}
			}
			return 1;
		} else {
			my $espeak_FH;
			my $espeak_PID;
			if ($espeak_PID = open($espeak_FH,'|-',$Espeak)) {
				select((select($espeak_FH), $| = 1)[0]); print $espeak_FH q{};
			} else {
				warn "can't run $Espeak: $!\n"; return;
			}
			# binmode($espeak_FH, ':unix');
			sub huphandler { kill 'KILL', $espeak_PID; }
			$SIG{HUP} = \&huphandler;
			if ($text eq '.') { print $espeak_FH "dot\n";
			} else { print $espeak_FH "$text\n";
			}
			# close $espeak_FH;   # Must Not Close! close Hangs, unkillable !
			wait;
			exit 0;
		}
	}
}

sub display_question {   my $question = shift; my %options = @_;
	# used by &ask and &confirm, but not by &choose ...
	&check_size();
	my ($firstline, $otherlines);  # 20131002 @otherlines => $otherlines
	if ($options{nofirstline}) {
		@OtherLines = &fmt($question);
	} else {
		($firstline,$otherlines) = split(/\r?\n/, $question, 2);
		@OtherLines = &fmt($otherlines);
		if ($firstline) { &puts("$firstline "); }
	}
	if (@OtherLines) {
		&puts("\r\n", join("\r\n", @OtherLines), "\r");
		&goto(1 + length $firstline, 0);
	}
	return scalar @OtherLines;
}
sub erase_lines {  # leaves cursor at beginning of line $_[0]
	&goto(0, $_[0]); print TTY "\e[J";
}
sub fmt { my $text = shift; my %options = @_;
	# Used by tiview, ask and confirm; formats the text within $maxcols cols
	my (@i_words, $o_line, @o_lines, $o_length, $last_line_empty, $w_length);
	my (@i_lines, $initial_space);
	@i_lines = split(/\r?\n/, $text);
	foreach $i_line (@i_lines) {
		if ($i_line =~ /^\s*$/) {   # blank line ?
			if ($o_line) { push @o_lines, $o_line; $o_line=q{}; $o_length=0; }
			if (! $last_line_empty) { push @o_lines,""; $last_line_empty=1; }
			next;
		}
		$last_line_empty = 0;

		if ($options{nofill}) {
			push @o_lines, substr($i_line, 0, $maxcols-1); next;
		}
		if ($i_line =~ s/^(\s+)//) {   # line begins with space ?
			$initial_space = $1; $initial_space =~ s/\t/   /g;
			if ($o_line) { push @o_lines, $o_line; }
			$o_line = $initial_space; $o_length = length $initial_space;
		} else {
			$initial_space = q{};
		}

		@i_words = split(' ', $i_line);
		foreach $i_word (@i_words) {
			$w_length = length $i_word;
			if (($o_length + $w_length) >= $maxcols) {
				push @o_lines, $o_line;
				$o_line = $initial_space; $o_length = length $initial_space;
			}
			if ($w_length >= $maxcols) {  # chop it !
				push @o_lines, substr($i_word,0,$maxcols-1); next;
			}
			if ($o_line) { $o_line .= ' '; $o_length += 1; }
			$o_line .= $i_word; $o_length += $w_length;
		}
	}
	if ($o_line) { push @o_lines, $o_line; }
	if ((scalar @o_lines) < $maxrows-2) { return(@o_lines);
	} else { return splice (@o_lines, 0, $maxrows-2);
	}
}
sub back_up {
	open(TTY, '>', '/dev/tty')   # 1.43
	 || (warn "Can't write /dev/tty: $!\n", return 0);
	print TTY "\r\e[K\e[A\e[K";
	close TTY;
}
1;

__END__

=pod

=head1 NAME

Term::Clui.pm - Perl module offering a Command-Line User Interface

=head1 SYNOPSIS

 use Term::Clui;
 $chosen = choose("A Title", @a_list);  # single choice
 @chosen = choose("A Title", @a_list);  # multiple choice
 # multi-line question-texts are possible...
 $x = choose("Which ?\n(Mouse, or Arrow-keys and Return)", @w);
 $x = choose("Which ?\n".help_text(), @w);

 if (confirm($text)) { do_something(); };

 $answer = ask($question);
 $answer = ask($question,$suggestion);
 $password = ask_password("Enter password:");
 $filename = ask_filename("Which file ?");  # with Tab-completion

 $newtext = edit($title, $oldtext);
 edit($filename);

 view($title, $text)  # if $title is not a filename
 view($textfile)  # if $textfile _is_ a filename

 edit(choose("Edit which file ?", grep(-T, readdir D)));

=head1 DESCRIPTION

Term::Clui
offers a high-level user interface to give the user of
command-line applications a consistent "look and feel".
Its metaphor for the computer is as a human-like conversation-partner,
and as each question/response is completed it is summarised onto one line,
and remains on screen, so that the history of the session gradually
accumulates on the screen and is available for review, or for cut/paste.
This user interface can therefore be intermixed with
standard applications which write to STDOUT or STDERR,
such as I<make>, I<pgp>, I<rcs> etc.

For the user, I<choose()> uses either
(since 1.50) the mouse;
or arrow keys (or hjkl) and Return;
also B<q> to quit, and SpaceBar or Button3 to highlight multiple choices.
I<confirm()> expects y, Y, n or N.
In general, ctrl-L redraws the (currently active bit of the) screen.
I<edit()> and I<view()> use the default EDITOR and PAGER if possible.  

It's fast, simple, and has few external dependencies.
It doesn't use I<curses> (which is a whole-of-screen interface);
it uses a small subset of vt100 sequences (up down left right normal
and reverse) which are very portable,
and also (since 1.50) the I<SET_ANY_EVENT_MOUSE> and I<kmous> (terminfo)
sequences,
which are supported by all I<xterm>, I<rxvt>, I<konsole>, I<screen>,
I<linux>, I<gnome> and I<putty> terminals.

There is an associated file selector, Term::Clui::FileSelect

Since version 1.60, a speaking interface is provided
for the visually-impaired user;
it employs I<eflite> or I<espeak>.
Speech is turned on if the I<CLUI_SPEAK> environment variable
is set to any non-empty string.
Since version 1.62, if I<speakup> is running,
it is silenced while Term::Clui runs, and then restored.
Because Term::Clui's metaphor for the computer
is a human-like conversation-partner, this works very naturally.
The application needs no modification.

There is an equivalent Python3 module,
with (as far as possible) the same calling interface, at
http://cpansearch.perl.org/src/PJB/Term-Clui-1.71/py/TermClui.py

This is Term::Clui.pm version 1.71

=head1 WINDOW-SIZE

Term::Clui attempts to handle the WINCH signal.
If the window size is changed,
then as soon as the user enters the next keystroke (such as ctrl-L)
the current question/response will be redisplayed to fit the new size.

The first line of the question, the one which will remain on-screen, is
not re-formatted, but is left to be dealt with by the width of the window.
Subsequent lines are split into blank-separated words which are
filled into the available width; lines beginning with white-space
are treated as the beginning of a new indented paragraph,
individual words which will not fit onto one line are truncated,
and successive blank lines are collapsed into one.
If the question will not fit within the available rows, it is truncated.

If the available choice items in a I<choose()> overflow the screen,
the user is asked to enter "clue" letters,
and as soon as the items matching them will fit onto the screen
they are displayed as a choice.

=head1 SUBROUTINES

=over 3

=item I<ask>( $question );  OR I<ask>( $question, $default );

Asks the user the question and returns a string answer,
with no newline character at the end.
If the optional second argument is present,
it is offered to the user as a default.
If the I<$question> is multi-line,
the entry-field is at the top to the right of the first line,
and the subsequent lines are formatted within the
screen width and displayed beneath, as with I<choose>.

For the user, left and right arrow keys move backward and forward
through the string, delete and backspace erase the previous character,
ctrl-A moves to the beginning, ctrl-E to the end,
and ctrl-D or ctrl-X clear the current string.

=item I<ask_password>( $question );

Does the same with no echo, as used for password entry.

=item I<ask_filename>( $question );

Uses I<Term::ReadLine::Gnu> to provide filename-completion with
the I<Tab> key, but also displays multi-line questions in the
same way as I<ask> and I<choose> do.
This function was introduced in version 1.65.

=item I<choose>( $question, @list );

Displays the question, and formats the list items onto the lines beneath it.

If I<choose> is called in a scalar context,
the user can choose an item using arrow keys (or hjkl) and Return,
or cancel the choice with a "q".
I<choose> then returns the chosen item,
or I<undefined> if the choice was cancelled.

If I<choose> is called in an array context,
the user can also mark an item with the SpaceBar.
I<choose> then returns the list of marked items,
(including the item highlit when Return was pressed),
or an empty array if the choice was cancelled.

A DBM database is maintained of the question and its chosen response.
The next time the user is offered a choice with the same question,
if that response is still in the list it is highlighted
as the default; otherwise the first item is highlighted.
Different parts of the code, or different applications using I<Term::Clui.pm>
can therefore exchange defaults simply by using the same question words,
such as "Which printer ?".
Multiple choices are not remembered, as the danger exists
that the user might fail to notice some of the highlit items
(for example, all the items might not fit onto one screen).

The database I<~/.clui_dir/choices> or I<$ENV{CLUI_DIR}/choices>
is available to be read or written if lower-level manipulation is needed,
and the I<EXPORT_OK> routines I<get_default>($question) and
I<set_default>($question, $choice) should be used for this purpose,
as they handle DBM's problem with concurrent accesses.
The whole default database mechanism can be disabled by
I<CLUI_DIR=OFF> if you really want to :-(

If the items won't fit on the screen, the user is asked to enter
a substring as a clue. As soon as the matching items will fit,
they are displayed to be chosen as normal. If the user pressed "q"
at this choice, they are asked if they wish to change their substring
clue; if they reply "n" to this, choose quits and returns I<undefined>.

If the $question is multi-line,
The first line is put at the top as usual with the choices
arranged beneath it; the subsequent lines are formatted within the
screen width and displayed at the bottom.
After the choice is made all but the first line is erased,
and the first line remains on-screen with the choice appended after it.
You should therefore try to arrange multi-line questions
so that the first line is the question in short form,
and subsequent lines are explanation and elaboration.

=item I<confirm>( $question );

Asks the question, takes "y", "n", "Y" or "N" as a response.
If the $question is multi-line, after the response, all but the first
line is erased, and the first line remains on-screen with I<Yes> or I<No>
appended after it; you should therefore try to arrange multi-line
questions so that the first line is the question in short form,
and subsequent lines are explanation and elaboration.
Returns true or false.

=item I<edit>( $title, $text );  OR  I<edit>( $filename );

Uses the environment variable EDITOR ( or I<vi> :-)
Uses RCS if directory RCS/ exists

=item I<sorry>( $message );

Similar to I<warn "Sorry, $message\n";>

=item I<inform>( $message );

Similar to I<warn "$message\n";> except that it doesn't add the
newline at the end if there already is one,
and it uses I</dev/tty> rather than I<STDERR> if it can.

=item I<view>( $title, $text );  OR  I<view>( $filename );

If the I<$text> is longer than a screenful, uses the environment
variable PAGER ( or I<less> ) to display it.
If it is one or two lines it just omits the title and displays it.
Otherwise it uses a simple built-in routine which expects either "q"
or I<Return> from the user; if the user presses I<Return>
the displayed text remains on the screen and the dialogue continues
after it, if the user presses "q" the text is erased.

If there is only one argument and it's a filename,
then the user's PAGER displays it,
except (since 1.65) if it's a I<.doc> file, when either
I<wvText>, I<antiword> or I<catdoc> is used to extract its contents first.

=item I<help_text>( $mode );

This returns a short help message for the user.
If I<mode> is "ask" then the text describes the keys the user has available
when responding to an I<&ask> question;
If I<mode> is "multi" then the text describes the keys
and mouse actions the user has available
when responding to a multiple-choice I<&choose> question;
otherwise, the text describes the keys
and mouse actions the user has available
when responding to a single-choice I<&choose>.

=back

=head1 EXPORT_OK SUBROUTINES

The following routines are not exported by default, but are
exported under the I<ALL> tag, so if you need them you should:

 import Term::Clui qw(:ALL);

=over 3

=item I<beep>()

Beeps.

=item I<timestamp>()

Returns a sortable timestamp string in "YYYYMMDD hhmmss" form.

=item I<get_default>( $question )

Consults the database I<~/.clui_dir/choices> or
I<$ENV{CLUI_DIR}/choices> and returns the choice that
the user made the last time this question was asked.
This is better than opening the database directly
as it handles DBM's problem with concurrent accesses.

=item I<set_default>( $question, $new_default )

Opens the database I<~/.clui_dir/choices> or
I<$ENV{CLUI_DIR}/choices> and sets the default response which will
be offered to the user made the next time this question is asked.
This is better than opening the database directly
as it handles DBM's problem with concurrent accesses.

=back

=head1 DEPENDENCIES

It requires Exporter, which is core Perl.
It uses Term::ReadKey if it's available;
and uses Term::Size if it's available;
if not, it tries I<tput> before guessing 80x24.

=head1 ENVIRONMENT

The environment variable I<CLUI_DIR> can be used (by programmer or user)
to override I<~/.clui_dir> as the directory in which I<choose()> keeps
its database of previous choices.
The whole default database mechanism can be disabled by
I<CLUI_DIR = OFF> if you really want to :-(

If either the LANG or the LC_TYPE environment variables
contain the string I<utf8> or I<utf-8> (case insensitive),
then I<choose()> and I<inform()> open I</dev/tty> with a I<utf8> encoding.

If the environment variable I<CLUI_SPEAK> is set
or if I<EDITOR> is set to I<emacspeak>,
and if I<flite> is installed,
then I<Term::Clui> will use I<flite>
to speak its questions and choices out loud.

If the environment variable I<CLUI_MOUSE> is set to I<OFF>
then I<choose()> will not interpret mouse-clicks as making a choice.
The advantage of this is that the mouse can then be used
to highlight and paste text from this window as usual.

I<Term::Clui> also consults the environment variables
HOME, LOGDIR, EDITOR and PAGER, if they are set.

=head1 EXAMPLES

These scripts using Term::Clui and Term::Clui::FileSelect are to
be found in the I<examples> subdirectory of the build directory.

=over 3

=item I<linux_admin>

I use this script a lot at work, for routine system administration of
linux boxes, particularly Fedora and Debian.  It includes crontab,
chkconfig, update-rc.d, visudo, vipw, starting and stopping daemons,
reconfiguring squid samba or apache, editing sysconfig or running
any of the system-config-* utilities, and much else.

=item I<audio_stuff>

This script offers an arrow-key-and-return interface integrating
aplaymidi, cdrecord, cdda2wav, icedax, lame, mkisofs, muscript,
normalize, normalize-audio,
mpg123, sndfile-play, timidity, wodim and so on,
allowing audio files to be ripped,
burned, played, or converted between Muscript, MIDI, WAV and MP3 formats.

=item I<login_shell>

This script offers the naive user arrow-key-and-return access
to a text-based browser, a mail client, a news client, ssh and ftp
and various other stuff.

=item I<test_script>

This is the test script, as used during development.

=item I<choose>

This is a script which wraps Term::Clui::choose for use at the shell-script
level. It can either choose between command-line arguments,
or, with the B<-f> (filter) option, between lines of STDIN, like grep.
A B<-m> (multiple) option allows multiple-choice.
This can be a very useful script, and you may want to copy it into
I</usr/local/bin/> or elsewhere in your PATH.

=back

=head1 AUTHOR

Original author:

Peter J Billam www.pjb.com.au/comp/contact.html

Current maintainer:

Graham Ollis

=head1 CREDITS

Based on some old perl 4 libraries, I<ask.pl>, I<choose.pl>,
I<confirm.pl>, I<edit.pl>, I<sorry.pl>, I<inform.pl> and I<view.pl>,
which were in turn based on some even older curses-based programs in I<C>.

=head1 SEE ALSO

 Term::Clui::FileSelect
 Term::ReadKey
 Term::Size
 http://www.pjb.com.au/
 http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
 http://search.cpan.org/~pjb
 festival(1)
 eflite(1)
 espeak(1)
 espeakup(1)
 edbrowse(1)
 emacspeak(1)
 perl(1)

There is an equivalent Python3 module,
with (as far as possible) the same calling interface, at
http://cpansearch.perl.org/src/PJB/Term-Clui-1.71/py/TermClui.py

=cut
