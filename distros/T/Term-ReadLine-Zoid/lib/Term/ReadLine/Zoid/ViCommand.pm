package Term::ReadLine::Zoid::ViCommand;

use strict;
use vars '$AUTOLOAD';
no strict 'refs';
use AutoLoader;
use base 'Term::ReadLine::Zoid';
no warnings; # undef == '' down here

our $VERSION = 0.05;

sub AUTOLOAD { # more intelligent inheritance
	my $sub = $AUTOLOAD;
	$sub =~ s/.*:://;
	my $m = $_[0]->can($sub) ? 'AutoLoader' : 'Term::ReadLine::Zoid';
	${$m.'::AUTOLOAD'} = $AUTOLOAD;
	goto &{$m.'::AUTOLOAD'};
}

=head1 NAME

Term::ReadLine::Zoid::ViCommand - a readline command mode

=head1 SYNOPSIS

This class is used as a mode under L<Term::ReadLine::Zoid>,
see there for usage details.

=head1 DESCRIPTION

This mode provides a "vi command mode" as specified by the posix spec for the sh(1)
utility. It intends to include at least all key-bindings
mentioned by the posix spec for the vi mode in sh(1).
It also contains some extensions borrowed from vim(1) and some private extensions.

This mode has a "kill buffer" that stores the last killed text so it can
be yanked again. This buffer has only one value, it isn't a "kill ring".

=head1 KEY MAPPING

Since ViCommand inherits from MultiLine, which in turn inherits 
from Term::ReadLine::Zoid, key bindings are also inherited unless explicitly overloaded.

Control-d is ignored in this mode.

=over 4

=cut

our %_keymap = (
	return  => 'accept_line',
	ctrl_D	=> 'bell',
	ctrl_Z	=> 'sigtstp',
	backspace => 'backward_char',
	escape	=> 'vi_reset',
	ctrl_A	=> 'vi_increment',
	ctrl_X	=> 'vi_increment',
	_on_switch => 'vi_switch',
	_isa	=> 'multiline', # but wait .. self_insert is overloaded
);

sub keymap { return \%_keymap }

sub vi_switch {
	my $self = shift;
	return $$self{_loop} = undef if $$self{_vi_mini_b};
	$$self{vi_command}   = '';
	$$self{vi_history} ||= [];
	$self->backward_char unless $_[1] or $$self{pos}[0] == 0;
}

our @vi_motions = (' ', ',', qw/0 b F l W ^ $ ; E f T w | B e h t/);
our %vi_subs = (
	'#'  => 'vi_comment',		'='  => 'vi_complete',
	'\\' => 'vi_complete',		'*'  => 'vi_complete',
	'@'  => 'vi_macro',		'~'  => 'vi_case',
	'.'  => 'vi_repeat',		' '  => 'forward_char',
	'^'  => 'vi_home',		'$'  => 'end_of_line',
	'0'  => 'beginning_of_line',	'|'  => 'vi_cursor',
	';'  => 'vi_c_repeat',		','  => 'vi_c_repeat',
	'_'  => 'vi_topic',		'-'  => 'vi_K',
	'+'  => 'vi_J',
	
	'l'  => 'forward_char',		'h' => 'backward_char',
	't'  => 'vi_F',			'T' => 'vi_F',
);
our %vi_commands = (
	'/' => 'bsearch',
	'?' => 'fsearch',
	'!' => 'shell',
	'q' => 'quit',
);

sub self_insert {
	my ($self, $key) = @_;

	if (length($key) > 1) { # no vague chars
		$self->bell;
		$$self{vi_command} = '';
	}
	else { $$self{vi_command} .= $key }

	if ($$self{vi_command} =~ /^[\/\?\:]/) {
		$self->vi_mini_buffer($key)
	}
	elsif ($$self{vi_command} =~ /^0|^(\d*)(\D)/) { # this is where a command gets executed
		my ($cnt, $cmd) = ($1||1, $2||'0');
		my $sub = $vi_subs{$cmd} || 'vi_'.uc($cmd);
		#print STDERR "string: $$self{vi_command} cnt: $cnt sub: $sub\n";
		my $r;
		if ($self->can($sub)) {
			my $s = $self->save();
			$r = $self->$sub($cmd, $cnt); # key, count
			push @{$$self{undostack}}, $s unless lc($cmd) eq 'u'
				or join("\n", @{$$s{lines}}) eq join("\n", @{$$self{lines}});
		}
		else { $self->bell() }
		$$self{vi_last_cmd} = $$self{vi_command}
			if $$self{vi_command} && ! grep( {$_ eq $cmd} @vi_motions, '.'); # for repeat ('.')
		$$self{vi_command} = '';
		#print STDERR "return: $r vi_last_cmd: $$self{vi_last_cmd}\n";
		return $r;
	}
	else {
		return if $$self{vi_command} =~ /^\d+$/;
		#print STDERR "string: $$self{vi_command} rejected\n";
		$self->bell;
		$$self{vi_command} = '';
	}
	return 0;
}

# ############ #
# Key bindings #
# ############ #

# Subs get args ($self, $key, $count)

sub vi_reset { $_[0]{vi_command} = ''; return 0 }

sub sigtstp { kill 20, $$ } # SIGTSTP

=item escape

Reset the command mode.

=item return

=item ^J

Return the current edit line to the application for execution.

=item ^Z

Send a SIGSTOP to the process of the application. Might not work when the application
ignores those, which is something shells tend to do.

=item i

Switch back to insert mode.

=item I

Switch back to insert mode at the begin of the edit line.

=item a

Enter insert mode after the current cursor position.

=item A

Enter insert mode at the end of the edit line.

=cut

sub vi_I {
	$_[0]{pos}[0] = 0 if $_[1] eq 'I';
	$_[0]->switch_mode();
}

sub vi_A {
	($_[1] eq 'A') ? $_[0]->end_of_line : $_[0]->forward_char ;
	$_[0]->switch_mode();
}

=item m

Switch to multiline insert mode, see L<Term::ReadLine::Zoid::MultiLine>.
(private extension)

=item M

Switch to multiline insert mode at the end of the edit buffer.
(private extension)

=cut

sub vi_M {
	if ($_[1] eq 'M') {
		$_[0]{pos}[1] = $#{$_[0]{lines}};
		$_[0]->end_of_line;
	}
	else { $_[0]->forward_char }
	$_[0]->switch_mode('multiline')
}

=item R

Enter insert mode with replace toggled on.
(vim extension)

=cut

sub vi_R {
	my $self = shift;
	return $self->vi_r(@_) if $_[0] eq 'r';
	$self->switch_mode();
	$$self{replace} = 1;
}

## more bindings are defined in __END__ section for autosplit ##

__END__

## Two helper subs ##

sub _get_chr { # get extra argument
	my $self = shift;
	my $chr =  $self->key_name( $self->read_key );
	return $self->vi_reset if $chr eq 'escape';
	return undef if length $chr > 1;
	#print STDERR "got argument chr: $chr\n";
	$$self{vi_command} .= $chr;
	return $chr;
}

sub _do_motion { # get and do a motion
	my ($self, $ignore, $cnt) = @_;
	my $key =  $self->key_name( $self->read_key );
	return $self->vi_reset if $key eq 'escape';
	return $self->bell
		unless grep {$_ eq $key} @vi_motions, $ignore, qw/left right up down home end/;
	my $vi_cmd = $$self{vi_command};
	#print STDERR "got argument motion: $key\n";
	my $re = 1;
	unless ($key eq $ignore) {
		my $pos = [@{$$self{pos}}]; # force copy
		$$self{vi_command} = (grep {$_ eq $key} qw/0 ^ $/) ? '' : $cnt ;
		$re = $self->do_key($key, $cnt);
		$$self{pos} = $pos unless $re; # reset pos if unsuccessfull
		$$self{pos}[0]++  if lc($key) eq 'e'
			and $$self{pos}[0] < length $$self{lines}[ $$self{pos}[1] ];
			# always one exception :S
	}
	$$self{vi_command} = $vi_cmd . $key;
	return $re;
}

=item #

Makes current edit line a comment that will be listed in the history,
but won't be executed.

Only works if the 'comment_begin' option is set.

=cut

sub vi_comment {
	$_[0]{lines}[ $_[0]{pos}[1] ] = $_[0]{config}{comment_begin}
		. ' ' . $_[0]{lines}[ $_[0]{pos}[1] ];
	$_[0]{poss}[0] += 2 unless $_[0]{poss}[1];
}

=item =

Display possible shell word completions, does not modify the edit line.

=item \

Do pathname completion (using File::Glob) and insert the largest matching
part in the edit line.

=item *

Do pathname completion but inserts B<all> matches.

=cut

sub vi_complete {
	my ($self, $key) = @_;

	return $self->possible_completions() if $key eq '=';

	my $buffer = join "\n", @{$$self{lines}};
	my $begin = substr $buffer, 0, $self->pos2off($$self{pos}), '';
	$begin =~ s/(\S*)$//;
	my $glob = $1;
	$$self{pos}[0] -= length $1;

	use File::Glob ':glob';
	$glob .= '*' unless $glob =~ /[\*\?\[]/;
	my @list = bsd_glob($glob, GLOB_TILDE | GLOB_BRACE);

	my $string;
	if ($key eq '\\') {
		@list = $self->longest_match(@list);
		$string = shift(@list);
		$self->output(@list);
	}
	elsif ($key eq '*') { $string = join ' ', @list }

	$$self{pos}[0] += length $string;
	@{$$self{lines}} = split /\n/, $begin . $string . $buffer;
	
	$self->switch_mode() if $key eq '*';
}

=item [I<count>] @ I<char>

Regard the contents of the alias _char as a macro with editing commands.
This seems a rather obfuscated feature of the posix spec to me. See also below
for the L<alias> command.

Note that the I<count> argument is not posix compliant, but it seems silly not
to use it.

=cut

sub vi_macro {
	my ($self, undef, $cnt) = @_;
	my $n = $self->_get_chr;
	#print STDERR "macro arg was: $n\n";
	return $self->bell unless $n =~ /^\w$/;
	return unless exists $$self{config}{aliases}{'_'.$n};
	my $macro = $$self{config}{aliases}{"_$n"};
	for (1..$cnt) {
		$self->switch_mode();
		$self->press($macro);
	}
}

=item [I<count>] ~

Reverse case for I<count> characters.

=cut

sub vi_case { # reverse case
	my ($self, undef, $cnt) = @_;
	my $str = substr $$self{lines}[ $$self{pos}[1] ], $$self{pos}[0], $cnt, '';
	$str =~ s/(([[:lower:]]+)|[[:upper:]]+)/$2 ? uc($1) : lc($1)/eg;
	substr $$self{lines}[ $$self{pos}[1] ], $$self{pos}[0], 0, $str;
	$$self{pos}[0] += length $str;
}

=item [I<count>] .

Repeat the last non-motion command.
If no count is specified the original count of the command is used.

=cut

sub vi_repeat {
	my ($self, undef, $cnt) = @_;
	undef $cnt if $$self{vi_command} !~ /^$cnt/;
	return $self->bell if ! length $$self{vi_last_cmd};
	#print STDERR "repeat last command: $$self{vi_last_cmd}\n";
	$$self{vi_last_cmd} =~ /^(\d*)(.)(.*)/;
	die "BUG: we ain't gonna loop all day !" if $2 eq '.';
	$$self{vi_command} = defined $cnt ? $cnt : $1 || '';
	$self->unread_key($3);
	$self->self_insert($2);
}

=item v

Edit the buffer with the editor specified by the C<EDITOR> environment variable
or the L<editor> option, defaults to 'vi'.

This function requires the L<File::Temp> module from cpan, which in turn needs 
File::Spec and other packages. If these are not available this functions is
disabled.

=cut

sub vi_V { 
	my $self = shift;
	my $string = $$self{config}{editor} || $ENV{EDITOR} || 'vi %';
	$string .= ' %' unless $string =~ /\%/;
	$self->shell($string);
}

=item [I<count>] l 

=item [I<count>] I<space>

Move the cursor to the right.

=item [I<count>] h 

Move the cursor to the left.

=cut

## vi_L and vi_H are implemented by parent left n right

=item [I<count>] w

=item [I<count>] W

Move the cursor to the begin of the next word or bigword.

(A bigword exists of non-whitespace chars, while a word
exists of alphanumeric chars only.)

=cut

sub vi_W { # no error, just end of line
	my ($self, $key, $cnt) = @_;
	my $w = ($key eq 'W') ? '\\S' : '\\w';
	my $l = $$self{lines}[ $$self{pos}[1] ];
	for (1..$cnt) {
		if ($l =~ /^.{$$self{pos}[0]}(.+?)(?<!$w)$w/) { $$self{pos}[0] += length $1 }
		else {
			$self->end_of_line;
			last;
		}
	}
	return 1;
}

=item [I<count>] e 

=item [I<count>] E 

Move the cursor to the end of the current word or bigword.

=cut

sub vi_E { # no error, just end of line
	my ($self, $key, $cnt) = @_;
	my $w = ($key eq 'E') ? '\\S' : '\\w';
	my $l = $$self{lines}[ $$self{pos}[1] ];
	for (1..$cnt) {
		if ($l =~ /^.{$$self{pos}[0]}($w?.*?$w+)/) { $$self{pos}[0] += length($1) - 1 }
		else {
			$self->end_of_line;
			last;
		}
	}
	return 1;
}

=item [I<count>] b 

=item [I<count>] B 

Move the cursor to the begin of the current word or bigword.

=cut

sub vi_B { # no error, just begin of line
	my ($self, $key, $cnt) = @_;
	my $w = ($key eq 'B') ? '\\S' : '\\w';
	my $l = $$self{lines}[ $$self{pos}[1] ];
	for (1..$cnt) {
		$l = substr($l, 0, $$self{pos}[0]);
		if ($l =~ /($w+[^$w]*)$/) { $$self{pos}[0] -= length $1 }
		else {
			$self->beginning_of_line;
			last;
		}
	}
	return 1;
}

=item ^

Move the cursor to the first non-whitespace on the edit line.

=item $

Move the cursor to the end of the edit line.

=item 0

Move the cursor to the begin of the edit line.

=cut

sub vi_home {
	my $self = shift;
	$$self{lines}[ $$self{pos}[1] ] =~ /^(\s*)/;
	$$self{pos}[0] = length $1;
	return 1;
}

=item [I<count>] |

Set the cursor to position I<count> (1-based).

=cut

sub vi_cursor { $_[0]{pos}[0] = $_[2] - 1; 1; }

=item [I<count>] f I<char>

Set cursor to I<count>'th occurrence of I<char> to the right.
The cursor is placed on I<char>.

=item [I<count>] F I<char>

Set cursor to I<count>'th occurrence of I<char> to the left.
The cursor is placed on I<char>.

=item [I<count>] t I<char>

Set cursor to I<count>'th occurrence of I<char> to the right.
The cursor is placed before I<char>.

=item [I<count>] T I<char>

Set cursor to I<count>'th occurrence of I<char> to the left.
The cursor is placed after I<char>.

=cut

sub vi_F {
	my ($self, $key, $cnt, $chr) = @_;

	unless ($chr) {
		$chr = $self->_get_chr();
		return $self->bell if length $chr > 1;
		$$self{vi_last_c_move} = [$key, $chr];
	}

	my ($l, $x) = ( $$self{lines}[ $$self{pos}[1] ], $$self{pos}[0] );
	if ($key eq 'T' or $key eq 'F') {
		$l = substr($l, 0, $x);
		return $self->bell unless $l =~ /.*((?:$chr.*){$cnt})$/;
		$$self{pos}[0] -= length($1) - (($key eq 'T') ? 1 : 0);
		return length($1);
	}
	else { # ($key eq 't' || $key eq 'f')
		return $self->bell unless $l =~ /^..{$x}((?:.*?$chr){$cnt})/;
		$$self{pos}[0] += length($1) - (($key eq 't') ? 1 : 0);
		return length($1);
	}
}

## vi_T is aliased to vi_F in %vi_subs 

=item [I<count>] ;

Repeat the last 'f', 'F', 't', or 'T' command. Count of last command is ignored.

=item [I<count>] ,

Like ';' but with direction reversed.

=cut

sub vi_c_repeat {
	my ($self, $key, $cnt) = @_;
	return $self->bell unless $$self{vi_last_c_move};
	my ($ckey, $chr) = @{ $$self{vi_last_c_move} };
	$ckey = ($ckey eq 't' or $ckey eq 'f') ? uc($ckey) : lc($ckey) if $key eq ',';
	$self->vi_F($ckey, $cnt, $chr);
}

=item [I<count>] c I<motion>

Delete characters between the current position and the position after the
I<motion>, I<count> applies to I<motion>. 
After the deletion enter insert mode.

The "motion" 'c' deletes the current edit line.

=item C

Delete from cursor to end of line and enter insert mode.

=cut

sub vi_C { # like vi_D but without killbuf and with insert mode
	my ($self, $key, $cnt) = @_;
	my $pos = [ @{$$self{pos}} ]; # force copy
	if ($key eq 'C') { $self->end_of_line }
	else { return unless $self->_do_motion('c', $cnt) }
	if ($$self{vi_command} =~ /cc$/) { splice(@{$$self{lines}}, $$self{pos}[1], 1) }
	else { $self->substring('', $pos, $$self{pos}) }
	$self->switch_mode();
}

=item S

Delete current line and enter insert mode.

=cut

sub vi_S { 
	my $self = shift;
	$$self{lines}[ $$self{pos}[1] ] = '';
	$self->{pos}[0] = 0;
	$self->switch_mode();
}

=item [I<count>] r I<char>

Replace the character under the cursor (and the I<count>
characters next to it) with I<char>.

=cut

sub vi_r { # this sub is an exception in the naming scheme
	my ($self, undef, $cnt) = @_;
	my $chr = $self->_get_chr();
	substr $$self{lines}[ $$self{pos}[1] ], $$self{pos}[0], $cnt, $chr x $cnt;
	$$self{pos}[0] += $cnt - 1;
}

=item [I<count>] _

Insert a white space followed by the last (or I<count>'th) bigword
from the previous history entry ans enter insert mode.

Quotes are not respected by this function.

=cut

sub vi_topic {
	my ($self, undef, $cnt) = @_;
	$cnt = ($cnt == 1 and $$self{vi_command} !~ /^1/) ? -1 : $cnt-1;
	return $self->bell unless @{$$self{history}};
	my $buffer = join "\n", $$self{history}[0];
	$buffer =~ s/^\s+|\s+$//g;
	my @words = split /\s+/, $buffer;
	my $string = " $words[$cnt]";
	$self->substring($string);
	$$self{pos}[0] .= length $string;
	$self->switch_mode();
}

=item [I<count>] x

Delete I<count> characters and place them in the save buffer.

=item [I<count>] X

Delete I<count> characters before the cursor position
and place them in the save buffer.

('x' is like 'delete', 'X' like backspace)

=cut

sub vi_X {
	my ($self, $key, $cnt) = @_;
	if ($key eq 'X') {
		return $self->bell if $$self{pos}[0] < $cnt;
		$$self{pos}[0] -= $cnt;
	}
	$$self{killbuf} = substr $$self{lines}[ $$self{pos}[1] ], $$self{pos}[0], $cnt, '';
}

=item [I<count>] d I<motion>

Delete from the current cursor position to the position resulting from I<count>
times I<motion>. The deleted part will be placed in the save buffer.

The "motion" 'd' deletes the current line.

=item D

Delete from the cursor position until the end of the line and put the deleted
part in the save buffer.

=cut

sub vi_D {
	my ($self, $key, $cnt) = @_;
	my $pos = [ @{$$self{pos}} ]; # force copy
	if ($key eq 'D') { $self->end_of_line }
	else { return unless $self->_do_motion('d', $cnt) }
	if ($$self{vi_command} =~ /dd$/) {
		$$self{killbuf} = splice(@{$$self{lines}}, $$self{pos}[1], 1)."\n";
	}
	else { $$self{killbuf} = $self->substring('', $pos, $$self{pos}) }
}

=item [I<count>] y I<motion>

Yank (copy) characters from the current cursor position to the position resulting from I<count>
times I<motion> to the save buffer.

the "motion" 'y' yanks the current line.

=item Y

Like y but from cursor till end of line.

=cut

sub vi_Y { # like vi_D but only copies, doesn't delete
	my ($self, $key, $cnt) = @_;
	my $pos = [ @{$$self{pos}} ]; # force copy
	if ($key eq 'Y') { $self->end_of_line }
	else { return unless $self->_do_motion('y', $cnt) }
	if ($$self{vi_command} =~ /yy$/) {
		$$self{killbuf} = $$self{lines}[ $$self{pos}[1] ]."\n";
	}
	else { $$self{killbuf} = $self->substring(undef, $pos, $$self{pos}) }
	$$self{pos} = $pos; # reset pos
}

=item [I<count>] p

Insert I<count> copies of the the save buffer after the cursor.

=item [I<count>] P

Insert I<count> copies of the the save buffer before the cursor.

=cut

sub vi_P {
	my ($self, $key, $cnt) = @_;
	return unless length $$self{killbuf};
	$self->forward_char if $key eq 'p';
	$self->substring($$self{killbuf} x $cnt);
}

=item u

Undo the last command that changed the edit line.

=item U

Undo all changes.

TODO all changes since when ? since entering the command mode ?

=cut

sub vi_U {
	my ($self, $key, $cnt) = @_;
	return $self->bell() unless @{$$self{undostack}};
	$self->restore(pop @{$$self{undostack}});
}

=item [I<count>] k

=item [I<count>] -

Go I<count> lines backward in history.

=cut

sub vi_K {
	$_[0]->previous_history || last for 1 .. $_[2];
	$_[0]->beginning_of_line;
}

=item [I<count>] j

=item [I<count>] +

Go I<count> lines forward in history.

=cut

sub vi_J {
	$_[0]->next_history || last for 1 .. $_[2];
	$_[0]->beginning_of_line;
}

=item [I<number>] G

Go to history entry number I<number>, or to the first history entry.

=cut

sub vi_G {
	return $_[0]->bell if $_[2] > @{$_[0]{history}};
	$_[0]->set_history( @{$_[0]{history}} - $_[2] );
	# we keep the history in the reversed direction
}

=item n

Repeat the last history search by either the '/' or '?' minibuffers
or the incremental search mode.

=item N

Repeat the last history search in the oposite direction.

=cut

sub vi_N { # last_search = [ dir, string, hist_p ]
	my ($self, $key, undef, $dir) = @_; # dir == direction
	return $self->bell unless $$self{last_search};
	$dir ||= $$self{last_search}[0];
	$dir =~ tr/bf/fb/ if $key eq 'N'; # reverse dir

	my $reg = eval { qr/$$self{last_search}[1]/ };
	return $self->bell if $@;

	my ($succes, $hist_p) = (0, $$self{last_search}[2]);
	#print STDERR "lookign from $hist_p for: $reg\n";
	if ($dir eq 'b') {
		while ($hist_p < $#{$$self{history}}) {
			$hist_p++;
			next unless $$self{history}[$hist_p] =~ $reg;
			$succes++;
			last;
		}
	}
	else { # $dir eq 'f'
		$hist_p = scalar @{$$self{history}} if $hist_p < 0;
		while ($hist_p > 0) {
			$hist_p--;
			next unless $$self{history}[$hist_p] =~ $reg;
			$succes++;
			last;
		}
	}
	#print STDERR "succes: $succes at: $hist_p\n";

	if ($succes) {
		$self->set_history($hist_p);
		$$self{last_search}[2] = $hist_p;
		return 1;
	}
	else { return $self->bell }
}

=item :

Opens a command mini buffer. This is a very minimalistic execution environment
that can for instance be used to modify options if the application doesn't
provide a method to do so. Also it is used for quick hacks ;)

The execution of this buffer happens entirely without returning to the application.

(This is a vim extension)

=cut

sub vi_mini_buffer { 
	my ($self, $key) = @_;

	$self->switch_mode('insert');
	my $save = $self->save();
	@$self{qw/_vi_mini_b prompt lines pos/} = (1, $key, [''], [0,0]);
	$self->loop();
	my $str = join "\n", @{$$self{lines}};
	@$self{qw/_vi_mini_b _loop/} = (undef, 1);
	$self->restore($save);
	$self->switch_mode('command', 'no_left');

	my $cmd = $key;
	if ($key eq ':') {
		$str =~ s/^([!\/?])|^\s*(\S+)(\s+|$)// or return $self->bell;
		$cmd = $1 || $2;
	}
	$cmd = exists($vi_commands{$cmd}) ? $vi_commands{$cmd} : $cmd;
	#print STDERR "mini buffer got cmd, string: $cmd, $str\n";
	return $self->bell unless $self->can($cmd);
	return $self->$cmd($str);
}

=item /

Opens a mini buffer where you can type a pattern to search backward through
the history.

The search patterns are not globs (as posix would have them), but
are evaluated as perl regexes.

An empty pattern repeats the previous search.

=item ?

Like '/' but searches in the forward direction.

=cut

sub bsearch {
	my ($self, $string) = @_;

	if (length $string) {
		$$self{last_search} = ['b', $string, -1];
		eval { qr/$string/ };
		if ($@) {
			$self->output($@);
			return $self->bell;
		}
	}

	return $self->vi_N('n', undef, 'b');
}

sub fsearch {
	my ($self, $string) = @_;

	if (length $string) {
		$$self{last_search} = ['f', $string, -1];
		eval { qr/$string/ };
		if ($@) {
			$self->output($@);
			return $self->bell;
		}
	}

	return $self->vi_N('n', undef, 'f');
}

=item ^A

If cursor is on a number, increment it. (This is a vim extension)

FIXME bit buggy

=item ^X

If cursor is on a number, decrement it. (This is a vim extension)

FIXME bit buggy

=cut

sub vi_increment {
	my ($self, $key) = @_;
	my ($l, $x) = ( $$self{lines}[ $$self{pos}[1] ], $$self{pos}[0] );
	my $add = ($key eq 'ctrl_A') ? 1 : -1;

	return $self->bell unless $l =~ /^(.{0,$x}?)(0x(?i:[a-f\d])+|\d+)(.*?)$/; # FIXME triple check this regexp
	my ($pre, $int, $post) = ($1, $2, $3);

	$int = ($int =~ /^0x/) ? sprintf("0x%x", hex($int) + $add) : ($int + $add) ;

	$$self{lines}[ $$self{pos}[1] ] = $pre . $int . $post;
}

# ######## #
# Commands #
# ######## #

=back

=head1 COMMANDS

These can be used from the ":" mini buffer. Some commands are borrowed from vim,
but no guarantee what so ever.

=over 4

=item B<quit>

Return undef to the application (like '^D' in insert mode).

=item B<set> [I<+o>|I<-o>] [I<option>=I<value>]

Set a key-value pair in the options hash
When the arg '+o' is given (or the option is preceded by 'no')
the option is deleted.

Can be used to change the ReadLine behaviour independent from the application.

=cut

sub quit { $_[0]{_loop} = undef }

sub set {
	my ($self, $string) = @_;
	$string =~ s/^\-o\s+|(\+o\s+|no(?=\w))//;
	my $switch_off = $1;
	$string =~ s/^(\w+)(=|\s*$)// or return $self->bell;
	my ($opt, $val) = ($1, ($2 eq '=') ? $string : 1);
	$val =~ s/^['"]|["']$//g;
	if ($switch_off) { delete $$self{config}{$opt} }
	else { $$self{config}{$opt} = $val }
	return 1;
}

=item B<ascii>

Output ascii values for the char in the edit line on the cursor position.

=cut

sub ascii {
	my $self = shift;
	my $chr = shift || substr( $$self{lines}[ $$self{pos}[1] ], $$self{pos}[0], 1);
	$chr =~ s/^\s*(\S).*/$1/;
	my $ord = ord $chr;
	$self->output( sprintf "<%s> %d, Hex %x, Octal 0%o\n", $chr, $ord, $ord, $ord );
	# <">  34,  Hex 22,  Octal 042
	return 1;
}

=item B<testchr>

Wait for a character input and output ascii values for it.

=cut

sub testchr { # FIXME needs more magic for non printable chars
	my $self = shift;
	print { $self->{OUT} } "Press any key\n";
	my $chr = $self->_get_chr;
	my $ord = ord $chr;
	$$self{_buffer} -= 1;
	return 1;
}

=item B<bindchr> I<chr>=I<keyname>

Map a char (or char sequence) to a key name.

=cut

sub bindchr {
	my $self = shift;
	my @args = (@_ == 1) ? (split /=/, $_[0]) : (@_);
	$self->SUPER::bindchr(@args);
}

=item B<bindkey> I<chr>=sub { I<code> }

Map a char (or char sequence) to a key name.

=cut

sub bindkey {
	my $self = shift;
	$self->SUPER::bindkey(@_) if @_ == 2;
	my @arg = split /=/, $_[0], 2;
	$arg[1] = eval $arg[1];
	return warn $@."\n\n" if $@;
	$self->SUPER::bindkey(@arg);
}


=item B<!>, B<shell> I<shellcode>

Eval a system command.
The '%' character in this string will be replace with the name of a tmp file
containing the edit buffer.
After execution this tmp file will be read back into the edit buffer.
Of course you can use an backslash to escape a literal '%'.

Note that this tmp file feature only works if you have L<File::Temp> installed.

=cut

sub shell {
	my ($self, $string) = @_;

	my ($fh, $file);
	if ($string =~ /(?<!\\)%/) {
		eval 'require File::Temp' || return $self->bell;
		($fh, $file) = File::Temp::tempfile('PERL_RL_Zoid_XXXXX', DIR => File::Spec->tmpdir);
		print $fh join "\n", @{$$self{lines}};
		close $fh;
		$string =~ s/(\\)\%|\%/$1 ? '%' : $file/ge;
	}

	#print STDERR "system: $string\n";
	print { $$self{OUT} } "\n";
	my $error = (exists $$self{config}{shell})
		? $$self{config}{shell}->($string) : system( $string ) ;

	if ($error) { printf { $$self{OUT} } "\nshell returned %s\n\n", $error >> 8  }
	elsif ($file) {
		open TMP, $file or return $self->bell;
		@{$$self{lines}} = map {chomp; $_} (<TMP>);
		close TMP;
		$$self{pos} = [ length($$self{lines}[-1]), $#{$$self{lines}} ];
	}
	$$self{_buffer} = 0;
	unlink $file if $file;

	return 1;
}

=item B<eval> I<perlcode>

Eval some perlcode for the most evil instant hacks.
The ReadLine object can be called as C<$self>.

=cut

sub eval {
	my ($self, $_code) = @_;
	print { $$self{OUT} } "\n";
	my $_re = eval $_code;
	print { $$self{OUT} } ($@ ? $@ : "$_re\n");
	$$self{_buffer} = 0;
	return 1;
}

=item B<alias> I<char>=I<macro>

Define a macro in an alias with a one character name.
These can be executed with the '@' command.
Non alphanumeric keys like "\n" and "\e" can be inserted with the standard perl 
escape sequences. You need to use "\\" for a literal '\'.

=back

=cut

sub alias {
	my ($self, $string) = @_;
	return $self->bell unless $string =~ /^(\w)=(.*)/;
	$$self{config}{aliases}{"_$1"} = $self->_parse_chrs($2);
	return 1;
}

sub _parse_chrs { # parse escape sequences do not eval entire string, might contain $ etc.
	my $string = pop;
	$string =~ s/(\\\\)||(\\0\d{2}|\\x\w{2}|\\c.|\\\w)/$1 ? '\\' : eval qq("$2")/eg;
	return $string;
}

=head1 ATTRIBS

These can be accessed through the C<Attribs> method (defined by the parent class). 

=over 4

=item aliases

This option is refers to a hash with aliases, used for the key binding for '@'.
Note that all aliases have a one character name prefixed with a "_", this is due to
historic implementations where the same hash is used for system aliases.
We B<don't> support aliases for the shell command, to have that you should
define your own shell subroutine (see below).

=item editor

Editor command used for the 'v' binding. The string is run by the L<shell> command.
This option defaults to the EDITOR enviroment variable or to "vi %".

=item shell

The value can be set to a CODE ref to handle the L<shell> command from the
mini-buffer and the 'v' key binding. It should return the exit status of the
command (like the perlfunc C<system()>).

=back

=head1 AUTHOR

Jaap Karssenberg || Pardus [Larus] E<lt>pardus@cpan.orgE<gt>

Copyright (c) 2004 Jaap G Karssenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Term::ReadLine::Zoid>

=cut

