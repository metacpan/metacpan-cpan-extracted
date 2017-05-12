package Term::ReadLine::Zoid::Base;

use strict;
no warnings;
use Term::ReadKey qw/ReadMode ReadKey GetTerminalSize/;
#use encoding 'utf8';
no warnings; # undef == '' down here

our $VERSION = '0.06';

$| = 1;

our @_key_buffer;

our %chr_map = ( # partial sequences
	"\e"    => '',
	"\e["   => '',
	"\eO"   => '',
	"\e[["  => '',
	( map {("\e[$_" => '')} (1 .. 24) ),

	"\e[2"	 => '',	"\e[5"	 => '',
	"\eO2"	 => '',	"\eO5"	 => '',
	"\e[1;2" => '',	"\e[1;5" => '',
);

our %chr_names = ( # named keys
	"\e"   => 'escape',
	"\cH"  => 'backspace',
	"\cI"  => 'tab',
	"\cJ"  => 'return',    # line feed
	"\cM"  => 'return',    # carriage return
	"\c?"  => 'backspace', # traditionally known as DEL

	"\e[A" => 'up',			"\eOA" => 'up',
	"\e[B" => 'down', 		"\eOB" => 'down',
	"\e[C" => 'right',		"\eOC" => 'right',
	"\e[D" => 'left', 		"\eOD" => 'left',
	"\e[F" => 'end',		"\eOF" => 'end',
	"\e[H" => 'home',		"\eOH" => 'home',

	"\e[1~"  => 'home',
	"\e[2~"  => 'insert',
	"\e[3~"  => 'delete',
	"\e[4~"  => 'end',
	"\e[5~"  => 'page_up',
	"\e[6~"  => 'page_down',
	"\e[11~" => 'f1',		"\eOP" => 'f1',		"\e[[A" => 'f1',
	"\e[12~" => 'f2',		"\eOQ" => 'f2',		"\e[[B" => 'f2',
	"\e[13~" => 'f3',		"\eOR" => 'f3',		"\e[[C" => 'f3',
	"\e[14~" => 'f4',		"\eOS" => 'f4',		"\e[[D" => 'f4',
	"\e[15~" => 'f5',					"\e[[E" => 'f5',
	"\e[17~" => 'f6',
	"\e[18~" => 'f7',
	"\e[19~" => 'f8',
	"\e[20~" => 'f9',
	"\e[21~" => 'f10',
	"\e[23~" => 'f11',
	"\e[24~" => 'f12',

	"\e[2A" => 'shift_up',		"\eO2A" => 'shift_up',		"\e[1;2A" => 'shift_up',
	"\e[2B" => 'shift_down',	"\eO2B" => 'shift_down',	"\e[1;2B" => 'shift_down',
	"\e[2C" => 'shift_right',	"\eO2C" => 'shift_right',	"\e[1;2C" => 'shift_right',
	"\e[2D" => 'shift_left',	"\eO2D" => 'shift_left',	"\e[1;2D" => 'shift_left',
	"\e[2F" => 'shift_end',		"\eO2F" => 'shift_end',		"\e[1;2F" => 'shift_end',
	"\e[2H" => 'shift_home',	"\eO2H" => 'shift_home',	"\e[1;2H" => 'shift_home',

	"\e[5A" => 'ctrl_up',		"\eO5A" => 'ctrl_up',		"\e[1;5A" => 'ctrl_up',
	"\e[5B" => 'ctrl_down',		"\eO5B" => 'ctrl_down',		"\e[1;5B" => 'ctrl_down',
	"\e[5C" => 'ctrl_right',	"\eO5C" => 'ctrl_right',	"\e[1;5C" => 'ctrl_right',
	"\e[5D" => 'ctrl_left',		"\eO5D" => 'ctrl_left',		"\e[1;5D" => 'ctrl_left',
	"\e[5F" => 'ctrl_end',		"\eO5F" => 'ctrl_end',		"\e[1;5F" => 'ctrl_end',
	"\e[5H" => 'ctrl_home',		"\eO5H" => 'ctrl_home',		"\e[1;5H" => 'ctrl_home',
);

#	'[6A' => 'ctrl_shift_up',	'O6A' => 'ctrl_shift_up',	'[1;6A' => 'ctrl_shift_up',
#	'[6B' => 'ctrl_shift_down',	'O6B' => 'ctrl_shift_down',	'[1;6B' => 'ctrl_shift_down',
#	'[6C' => 'ctrl_shift_right',	'O6C' => 'ctrl_shift_right',	'[1;6C' => 'ctrl_shift_right',
#	'[6D' => 'ctrl_shift_left',	'O6D' => 'ctrl_shift_left',	'[1;6D' => 'ctrl_shift_left',
#	'[6F' => 'ctrl_shift_end',	'O6F' => 'ctrl_shift_end',	'[1;6F' => 'ctrl_shift_end',
#	'[6H' => 'ctrl_shift_home',	'O6H' => 'ctrl_shift_home',	'[1;6H' => 'ctrl_shift_home',

#	'[7A' => 'ctrl_alt_up',		'O7A' => 'ctrl_alt_up',		'[1;7A' => 'ctrl_alt_up',
#	'[7B' => 'ctrl_alt_down',	'O7B' => 'ctrl_alt_down',	'[1;7B' => 'ctrl_alt_down',
#	'[7C' => 'ctrl_alt_right',	'O7C' => 'ctrl_alt_right',	'[1;7C' => 'ctrl_alt_right',
#	'[7D' => 'ctrl_alt_left',	'O7D' => 'ctrl_alt_left',	'[1;7D' => 'ctrl_alt_left',
#	'[7F' => 'ctrl_alt_end',	'O7F' => 'ctrl_alt_end',	'[1;7F' => 'ctrl_alt_end',
#	'[7H' => 'ctrl_alt_home',	'O7H' => 'ctrl_alt_home',	'[1;7H' => 'ctrl_alt_home',

# ############## #
# base functions #
# ############## #

sub bell {
	#print STDERR 'bell called by: ',join(', ', caller)."\n";
	exists( $_[0]{config}{bell} )
		? $_[0]{config}{bell}->()
		: print { $_[0]{OUT} } "\cG" ; # ^G == \007 == BELL
	return 0;
}

sub loop {
	my $self = shift;
	$$self{lines} = [''] unless @{$$self{lines}};
	$$self{term_size} = [ (GetTerminalSize($$self{IN}))[0,1] ];
	@ENV{'COLUMNS', 'LINES'} = @{$$self{term_size}} if $$self{config}{autoenv};
	$self->draw();
	$$self{_loop} = 1;
	while ($$self{_loop}) {
		$self->do_key();
		while (@_key_buffer) { $self->do_key() }
		$self->draw();
	}
	$self->cursor_at(@{$$self{_buffer_end}});
}

sub beat { $_[0]{config}{beat}->() if exists $_[0]{config}{beat} }

sub read_key { die "deprecated warning" if $_[1];
	my $self = shift;
	return shift @_key_buffer if scalar @_key_buffer;

	my $chr;
	ReadMode('raw', $$self{IN});
	{
		local $SIG{WINCH} = sub { $$self{_SIGWINCH} = 1 };

		while ( not defined ($chr = ReadKey(1, $$self{IN})) ) { $self->beat() }

		my $n_chr;
		if (
			exists $chr_map{$chr} and
			( $$self{config}{low_latency} or ($n_chr = ReadKey(0.05, $$self{IN})) )
		) {
			$chr .= $n_chr;
			while (exists $chr_map{$chr}) {
				while ( not defined ($n_chr = ReadKey(1, $$self{IN})) ) { $self->beat() }
				$chr .= $n_chr;
			}
			unless (exists $chr_names{$chr}) {
				$chr =~ s/^(.)(.*)/$1/s;
				push @_key_buffer, split '', $2;
			}
		}
	}
	ReadMode('normal', $$self{IN});

	return $chr;
}

sub do_key {
	my ($self, $key) = (shift, shift);
	$key = $self->read_key() unless length $key;

	# $self->key_name()
	if (exists $chr_names{$key}) { $key = $chr_names{$key} }
	elsif (length $key < 2) {
		my $ord = ord $key;
		$key =	  ($ord < 32)   ? 'ctrl_'  . (chr $ord + 64)
			: ($ord == 127) ? 'ctrl_?' : $key ;
	}

	# $self->key_binding
	my $map = $$self{keymaps}{$$self{mode}};
	my $sub;
	DO_KEY:
	if (exists $$map{$key}) { $sub = $$map{$key} }
	elsif (exists $$map{_isa}) {
		$map = $$self{keymaps}{ $$map{_isa} }
			|| return warn "$$map{_isa}: no such keymap\n\n";
		goto DO_KEY;
	}
	elsif (exists $$map{_default}) { $sub = $$map{_default} }
	else { $sub = 'bell' }

	#print STDERR "# key: $key sub: $sub\n";
	my $re = ref($sub) ? $sub->($self, $key, @_) : $self->$sub($key, @_) ;
	$$self{last_key} = $key;
	return $re;
}

sub print {
	# The idea is to let the terminal render the line wrap
	# but calculate what it will do in order to get the cursor position right.
	my ($self, $lines, $pos) = @_;
#	use Data::Dumper;
#	print STDERR Dumper $lines, $pos;
	if ($$self{_SIGWINCH}) { # GetTerminalSize is kind of heavy
		$$self{term_size} = [ (GetTerminalSize($$self{IN}))[0,1] ];
		@ENV{'COLUMNS', 'LINES'} = @{$$self{term_size}} if $$self{config}{autoenv};
		$$self{_SIGWINCH} = 0;
	}

	my ($width, $higth) = @{$$self{term_size}};

	# calculate how line wrap will work out
	my @nlines = map { int(print_length($_) / $width) } @$lines;
	$$pos[1] += $nlines[$_] for 0 .. $$pos[1] - 1;
	$$pos[1] += int($$pos[0] / $width);
	$$pos[0] %= $width;
#	print STDERR Dumper \@nlines, $pos;

	# get the lines at the right position
	my $buffer = -1; # always 1 lines minimum
	$buffer += 1 + $_ for @nlines;
	my $null = 1;
	if ($buffer > $higth) { # big buffer or small screen :$
		# FIXME does not yet reckon with line wrap
		# FIXME some +1 or -1 offsets not right
		my $offset = $$pos[1] - $$self{scroll_pos};
		if ($offset < 0) { $$self{scroll_pos} = $$pos[1] }
		elsif ($offset > $higth) { $$self{scroll_pos} += $offset - $higth }
		@$lines = splice @$lines, $$self{scroll_pos}, $higth;
		$$pos[1] -= $$self{scroll_pos};
		$$self{_buffer_end} = [$width, $higth];
		$$self{_buffer} = $higth;
	}
	else { # normal readline buffer
		if ($buffer > $$self{_buffer}) { # clear screen area
			$self->cursor_at(@{$$self{term_size}});
			print { $$self{OUT} } "\n" x ($buffer - $$self{_buffer});
			$$self{_buffer} = $buffer;
		}
		$null = $$self{term_size}[1] - $$self{_buffer};
		$$self{_buffer_end} = [print_length($$lines[-1]), $null + $buffer]; # save real cursor
	}
	$self->cursor_at(1, $null);
	print { $$self{OUT} } $$lines[$_], "\e[K\n" for 0 .. $#$lines - 1;
	print { $$self{OUT} } $$lines[-1], "\e[J";

	$self->cursor_at($$pos[0]+1, $$pos[1]+$null); # set cursor
}

# ######### #
# utilities #
# ######### #

sub TermSize { (GetTerminalSize($_[0]{IN}))[0,1] }

sub key_name {
	if (exists $chr_names{$_[1]}) { return $chr_names{$_[1]} }
	elsif (length $_[1] < 2) {
		my $ord = ord $_[1];
		return	  ($ord < 32)   ? 'ctrl_'  . (chr $ord + 64)
			: ($ord == 127) ? 'ctrl_?' : $_[1] ;
	}
	else { return $_[1] }
}

sub key_binding {
	my ($self, $key, $mode) = @_;
	$mode ||= $$self{mode};

	my $map = $$self{keymaps}{$mode};
	FIND_KEY:
	if (exists $$map{$key}) { return $$map{$key} }
	elsif (exists $$map{_isa}) {
		$map = $$self{keymaps}{ $$map{_isa} }
			|| return warn "$$map{_isa}: no such keymap\n\n";
		goto FIND_KEY;
	}
	else { return undef }
}

sub press {
	my $self = shift;
	push @_key_buffer, (@_>1) ? (@_) : (split '', $_[0]);
	while (scalar @_key_buffer) { $self->do_key() }
}

sub unread_key {
	my $self = shift;
	unshift @_key_buffer, (@_>1) ? (@_) : (split '', $_[0]);
}

sub pos2off {
	my ($self, $pos) = @_;
	$pos ||= $$self{pos};
	my $off = $$pos[0];
	$off += 1 + length $$self{lines}[$_] for 0 .. $$pos[1] - 1;
	return $off;
}

sub output {
	my ($self, @items) = @_;

	$self->cursor_at(@{$$self{_buffer_end}});
	print { $$self{OUT} } "\n";

	my ($max, $cnt) = ($$self{config}{maxcomplete}, scalar @items);
	$self->_ask($cnt) or return if $max and $max =~ /^\d+$/ and $cnt > $max;

	@items = ($cnt > 1) ? ($self->col_format(@items)) : (split /\n/, $items[0]);

	$$self{_buffer} = (@items < $$self{_buffer}) ? ($$self{_buffer} - @items) : 0;
	if (@items > $$self{term_size}[1]) {
		$self->_ask($cnt) or return if $max and $max eq 'pager';
		my $pager = $ENV{PAGER} || 'more';
		eval {
			local $SIG{PIPE} = 'IGNORE';
			open PAGER, "| $pager" || die;
			print PAGER join("\n", @items), "\n";
			close PAGER;
		} ;
	}
	else { print { $$self{OUT} } join("\n", @items), "\n" }
}

sub _ask {
	my ($self, $cnt) = @_;
	print { $$self{OUT} } "Display all $cnt possibilities? [yN]";
	my $answ = $self->read_key();
	print { $$self{OUT} } "\n";
	return( ($answ =~ /y/i) ? 1 : 0 );
}

sub col_format { # takes minimum number of rows, but fills cols first
	my ($self, @items) = @_;

	my $len = 0;
	$_ > $len and $len = $_ for map {length $_} @items;
	$len += 2; # spacing
	my ($width) = $self->TermSize();
	return @items if $width < (2 * $len); # rows == items
	return join '  ', @items if $width > (@items * $len); # 1 row

	my $cols = int($width / $len ) - 1; # 0 based
	my $rows = int(@items / ($cols+1)); # 0 based ceil
	$rows -= 1 unless @items % ($cols+1); # tune ceil
	my @rows;
	for my $r (0 .. $rows) {
		my @row = map { $items[ ($_ * ($rows+1)) + $r] } 0 .. $cols;
		push @rows, join '', map { $_ .= ' 'x($len - length $_) } @row;
	}
	#print STDERR scalar(@items)." items, $len long, $width width, $cols+1 cols, $rows+1 rows\n";
	return @rows;
}

# ################# #
# Key binding stuff #
# ################# #

sub bindchr {
	my ($self, $chr, $key) = @_;
	if ($chr =~ /^\^(.)$/) { $chr = eval qq/"\\c$1"/ }
	$chr_names{$chr} = $key;
	chop $chr;
	while (length $chr) {
		$chr_map{$chr} = '';
		chop $chr;
	}
}

sub recalc_chr_map {
	my $self = shift;
	%chr_map = ();
	while (my ($k,$v) = each %chr_names) {
		$self->bindchr($k, $v);
	}
}

# ########## #
# ANSI stuff #
# ########## #

sub cursor_at { print { $_[0]{OUT} } "\e[$_[2];$_[1]H" } # ($x, $y) 1-based !

sub new_line {
	my $self = shift;
	return unless -t $$self{OUT} and -t $$self{IN};

	ReadMode 'raw';
	my $r;
	print { $$self{OUT} } "\e[6n";
	$r = ReadKey( -1, $$self{IN}) || return print { $$self{OUT} } "\n";
	while ($r =~ /^(\e|\e\[\d*|\e\[\d+;\d*)$/) { $r .= ReadKey -1, $$self{IN} }
	# in this case timed read doesn't work :(
	ReadMode 'normal';

	if ($r =~ /^\e\[\d+;(\d+)\D$/) {
		print { $$self{OUT} } "\n" if $1 > 1;
	}
	else {
		$self->unread_key($r);
		print { $$self{OUT} } "\n";
	}
}

sub clear_screen { print { $_[0]{OUT} } "\e[2J" }

sub print_length {
	my $string = pop;
	$string =~ s{\e\[[\d;]*\w}{}g; # strip ansi codes
	return length $string;
}

## Sequences from the "How to change the title of an xterm" howto
##  <http://www.tldp.org/HOWTO/Xterm-Title.html>
sub title {
	my ($self, $title) = @_;
	return unless $ENV{TERM};
	my $string =
		($ENV{TERM} =~ /^((ai)?xterm.*|dtterm|screen)$/) ? "\e]0;$title\cG" :
		($ENV{TERM} eq 'iris-ansi') ? "\eP1.y$title\e\\" :
		($ENV{TERM} eq 'sun-cmd')   ? "\e]l$title\e\\"   : undef ;
	print { $$self{OUT} } $string if $string;
}

1;

__END__

=head1 NAME

Term::ReadLine::Zoid::Base - atomic routines

=head1 DESCRIPTION

This module contains some atomic operations used by all
Term::ReadLine::Zoid objects. It is intended as a base class.

At the very least, to child class needs to define a C<default()> function
to handle key bindings and a C<draw()> function
which in turn calls C<print()>. Also the attributes C<IN> and C<OUT>
should contain valid filehandles.

=head1 METHODS

=head2 ANSI stuff

=over 4

=item C<cursor_at($x, $y)>

Positions the cursor on screen, dimensions are 1-based.

=item C<clear_screen()>

Clear screen.

=item C<title($string)>

Set terminal title to C<$string>. When using for example xterm(1)
this is the window name.

=item C<print_length($string)>

Returns the printable length of $string, not counting (some) ansi sequences.

=back

=head2 Private api

Methods for use in overload classes.
I<Avoid using these methods from the application.>

=over 4

=item C<bell()>

Notify the user of an error or limit.

=item C<loop()>

Low level function used by L<readline>. 
Calls C<draw()> and C<do_key()>.

=item C<beat()>

Method called by intervals while waiting for input, to be overloaded.

=item C<read_key()>

Returns one key read from input (this is the named key, not the char when mapped).

=item C<do_key($key)>

Execute a key, calls subroutine for a key binding or the default binding.
If C<$key> is undefined C<read_key()> is called first.

=item C<press($string)>

Do chars in C<$string> like they were typed on the keyboard. Used for testing puposes
and to make macros possible.

If you give more then one argument, these are considered individual characters, use this to
press named keys.

=item C<unread_key($string)>

Unshifts characters on the read buffer, arguments the same as C<press()>.

=item C<key_name($chr)>

Returns a name for a character or character sequence.

=item C<key_binding($key, $mode)>

Returns the keybinding for C<$key> in C<$mode>, mode defaults to the current one.

=item C<bindchr($chr, $key)>

Bind a key name to a character, or a character sequence. All bindings of this kind
are global (you're using only one keyboard, right ?).

=item C<recalc_chr_map()>

Recalculates the chr map, you need to call this after deleting from C<%chr_names>.

=item C<print($lines, $pos)>

Low level function used by L<draw>. Both arguments need to be array references.

=back

=head1 BUGS

Undefined behaviour when the buffer has more lines then the terminal.

Please mail the author if you find any other bugs.

=head1 AUTHOR

Jaap Karssenberg || Pardus [Larus] E<lt>pardus@cpan.orgE<gt>

Copyright (c) 2004 Jaap G Karssenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Term::ReadLine::Zoid>

=cut

