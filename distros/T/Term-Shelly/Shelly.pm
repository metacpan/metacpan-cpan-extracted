=pod

=head1 NAME

Term::Shelly - Yet Another Shell Kit for Perl

=head1 VERSION

$Id: Shelly.pm,v 1.5 2004/06/04 04:21:23 psionic Exp $

=head1 GOAL

I needed a shell kit for an aim client I was writing. All of the Term::ReadLine modules are do blocking reads in doing their readline() functions, and as such are entirely unacceptable. This module is an effort on my part to provide the advanced functionality of great ReadLine modules like Zoid into a package that's more flexible, extendable, and most importantly, allows nonblocking reads to allow other things to happen at the same time.

=head1 NEEDS

- Settable key bindings
- Tab completion
- Support for window size changes (sigwinch)
- movement in-line editing.
- vi mode (Yeah, I lub vi)
- history
- Completion function calls

- Settable callbacks for when we have an end-of-line (EOL binding?)

=cut

package Term::Shelly;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.01';

# Default perl modules...
use IO::Handle; # I need flush()... or do i?;

# Get these from CPAN
use Term::ReadKey;

# Useful constants we need...

# for find_word_bound()
use constant WORD_BEGINNING => 0;     # I want the beginning of this word.
use constant WORD_END => 1;           # I want the end of the word.
use constant WORD_ONLY => 2;          # Trailing spaces are important.
use constant WORD_REGEX => 4;         # I want to specify my own regexp

# Some key constant name mappings.
my %KEY_CONSTANTS = (
							"\e[A"      => "UP",
							"\e[B"      => "DOWN",
							"\e[C"      => "RIGHT",
							"\e[D"      => "LEFT",
						  );

# stty raw, basically
ReadMode 3;

# I need to know how big the terminal is (columns, anyway)

=pod

=head1 DESCRIPTION

=over 4

=cut

sub new ($) {
	my $class = shift;

	my $self = {
		"input_line" => "",
		"input_position" => 0,
		"leftcol" => 0,
	};

	bless $self, $class;

	($self->{"termcols"}) = GetTerminalSize();
	$SIG{WINCH} = sub { ($self->{"termcols"}) = GetTerminalSize(); $self->fix_inputline() };
	my $bindings = {
		"LEFT"        => "backward-char",
		"RIGHT"       => "forward-char",
		"UP"          => "up-history",
		"DOWN"        => "down-history",

		"BACKSPACE"   => "delete-char-backward",
		"^H"          => "delete-char-backward",
		"^?"          => "delete-char-backward",
		"^W"          => "delete-word-backward",

		"^U"          => "kill-line",

		"^J"          => "newline",
		"^M"          => "newline",

		"^A"          => "beginning-of-line",
		"^E"          => "end-of-line",
		"^K"          => "kill-to-eol",
		"^L"          => "redraw",

		"^I"          => "complete-word",
		"TAB"         => "complete-word",

		#"^T"          => "expand-line",
	};

	my $mappings = {
		"backward-char"          => \&backward_char,
		"forward-char"           => \&forward_char,
		"delete-char-backward"   => \&delete_char_backward,
		"kill-line"              => \&kill_line,
		"newline"                => \&newline,
		"redraw"                 => \&fix_inputline,
		"beginning-of-line"      => \&beginning_of_line,
		"end-of-line"            => \&end_of_line,
		"delete-word-backward"   => \&delete_word_backward,

		"complete-word"          => \&complete_word,
		#"expand-line"            => \&expand_line,
	};

	$self->{"bindings"} = $bindings;
	$self->{"mappings"} = $mappings;
	return $self;
}

=pod

=item $sh->do_one_loop()

Does... one... loop. Makes a pass at grabbing input and processing it. For
speedy pasts, this loops until there are no characters left to read.
It will handle event processing, etc.

=cut

# Nonblocking readline
sub do_one_loop ($) { 
	my $self = shift;
	my $char;

	# ReadKey(.1) means no timeout waiting for data, thus is nonblocking
	while (defined($char = ReadKey(.1))) {
		$self->handle_key($char);
	}
	
}

=pod

=item handle_key($key)

Handle a single character input. This is not a "key press" so much as doing all
the necessary things to handle key presses.

=cut

sub handle_key($$) {
	my $self = shift;
	my $char = shift;

	my $line = $self->{"input_line"} || "";
	my $pos = $self->{"input_position"} || 0;

	if ($self->{"escape"}) {
		$self->{"escape_string"} .= $char;
		if ($self->{"escape_expect_ansi"}) {
			$self->{"escape_expect_ansi"} = 0 if ($char =~ m/[a-zA-Z]/);
		}

		$self->{"escape_expect_ansi"} = 1 if ($char eq '[');
		$self->{"escape"} = 0 unless ($self->{"escape_expect_ansi"});

		unless ($self->{"escape_expect_ansi"}) {
			my $estring = $self->{"escape_string"};

			$self->{"escape_string"} = undef;
			return $self->execute_binding("\e".$estring);
		}

		return 0;
	}

	if ($char eq "\e") {      # Trap escapes, they're speshul.
		$self->{"escape"} = 1;
		$self->{"escape_string"} = undef;
		
		# What now?
		return 0;
	}

	if ((ord($char) < 32) || (ord($char) > 126)) {   # Control character
		$self->execute_binding($char);
		return 0;
	}

	if ((defined($char)) && (ord($char) >= 32)) {
		substr($line, $pos, 0) = $char;
		$self->{"input_position"}++;

		# If we just did a tab completion, kill the state.
		delete($self->{"completion"}) if (defined($self->{"completion"}));
	}

	$self->{"input_line"} = $line;
	$self->fix_inputline();
}

=pod

=item execute_binding(raw_key)

Guess what this does? Ok I'll explain anyway... It takes a key and prettifies
it, then checks the known key bindings for a mapping and checks if that mapping
is a coderef (a function reference). If it is, it'll call that function. If
not, it'll do nothing. If it finds a binding for which there is no mapped
function, it'll tell you that it is an unimplemented function.

=cut

sub execute_binding ($$) {
	my $self = shift;
	my $str = shift;
	my $key = $self->prettify_key($str);

	my $bindings = $self->{"bindings"};
	my $mappings = $self->{"mappings"};

	if (defined($bindings->{$key})) {

		# Check if we have stored completion state and the next binding is
		# not complete-word. If it isn't, then kill the completion state.
		if (defined($self->{"completion"}) && 
			 $bindings->{$key} ne 'complete-word') {
			delete($self->{"completion"});
		}

		if (ref($mappings->{$bindings->{$key}}) eq 'CODE') {

			# This is a hack, passing $self instead of doing:
			# $self->function, becuase I don't want to do an eval.

			return &{$mappings->{$bindings->{$key}}}($self);

		} else {
			error("Unimplemented function, " . $bindings->{$key});
		}
	}

	return 0;
}

=pod

=item prettify_key(raw_key)

This happy function lets me turn raw input into something less ugly. It turns
control keys into their equivalent ^X form. It does some other things to turn
the key into something more readable 

=cut

sub prettify_key ($$) {
	my $self = shift;
	my $key = shift;

	# Return ^X for control characters, like CTRL+A...
	if (length($key) == 1) {   # One-character keycombos should only be ctrl keys
		if (ord($key) <= 26) {  # Control codes, another check anyway...
			return "^" . chr(65 + ord($key) - 1);
		}
		if (ord($key) == 127) { # Speshul backspace key
			return "^?";
		}
		if (ord($key) < 32) {
			return "^" . (split("", "\]_^"))[ord($key) - 28];
		}
	}

	# Return ESC-X for escape shenanigans, like ESC-W
	if (length($key) == 2) {
		my ($p, $k) = split("", $key);
		if ($p eq "\e") {    # This should always be an escape, but.. check anyway
			return "ESC-" . $k;
		}
	}

	# Ok, so it's not ^X or ESC-X, it's gotta be some ansi funk.
	return $KEY_CONSTANTS{$key};
}

=pod 

=item real_out($string)

This function allows you to bypass any sort of evil shenanigans regarding output fudging. All this does is 'print @_;'

Don't use this unless you know what you're doing.

=cut

sub real_out {
	my $self = shift;
	print @_;
}

sub out ($;$) {
	my $self = shift;
	$self->real_out("\r\e[2K", @_, "\n");
	$self->fix_inputline();
}

sub error ($$) { 
	my $self = shift;
	print STDERR "*> ", @_, "\n";
	$self->fix_inputline();
}

=pod 

=item fix_inputline

This super-happy function redraws the input line. If input_position is beyond the bounds of the terminal, it'll shuffle around so that it can display it. This function is called just about any time any key is hit.

=cut

sub fix_inputline {
	my $self = shift;

	print "\r\e[2K";

	# If we're past the end of the terminal line, shuffle back!
	if ($self->{"input_position"} - $self->{"leftcol"} <= 0) {
		$self->{"leftcol"} -= 30;
		$self->{"leftcol"} = 0 if ($self->{"leftcol"} < 0);
	}

	# If we're before the beginning of the terminal line, shuffle over!
	if ($self->{"input_position"} - $self->{"leftcol"} > $self->{"termcols"}) {
		$self->{"leftcol"} += 30;
	}

	# Can se show the whole line? If so, do it!
	if (length($self->{"input_line"}) < $self->{"termcols"}) {
		$self->{"leftcol"} = 0;
	}

	# only print as much as we can in this one line.
	print substr($self->{"input_line"}, $self->{"leftcol"}, $self->{"termcols"});
	print "\r";
	print "\e[" . ($self->{"input_position"} - $self->{"leftcol"}) . 
	      "C" if ($self->{"input_position"} > 0);
	STDOUT->flush();
}

sub newline {
	my $self = shift;
	# Process the input line.

	$self->real_out("\n");
	print "You wrote: " . $self->{"input_line"} . "\n";

	$self->{"input_line"} = "";
	$self->{"input_position"} = 0;
}

sub kill_line {
	my $self = shift;
	$self->{"input_line"} = "";
	$self->{"input_position"} = 0;
	$self->{"leftcol"} = 0;

	#real_out("\r\e[2K");

	$self->fix_inputline();

	return 0;
}

sub forward_char {
	my $self = shift;
	if ($self->{"input_position"} < length($self->{"input_line"})) {
		$self->{"input_position"}++;
		$self->real_out("\e[C");
	}
}

sub backward_char {
	my $self = shift;
	if ($self->{"input_position"} > 0) {
		$self->{"input_position"}--;
		$self->real_out("\e[D");
	}
}

sub delete_char_backward {
	my $self = shift;
	#"delete-char-backward"   => \&delete_char_backward,
	if ($self->{"input_position"} > 0) {
		substr($self->{"input_line"}, $self->{"input_position"} - 1, 1) = '';
		$self->{"input_position"}--;

		$self->fix_inputline();
	}
}

sub beginning_of_line {
	my $self = shift;
	$self->{"input_position"} = 0;
	$self->{"leftcol"} = 0;
	$self->fix_inputline();
}

sub end_of_line {
	my $self = shift;
	$self->{"input_position"} = length($self->{"input_line"});
	$self->fix_inputline();
}

sub delete_word_backward {
	my $self = shift;
	my $pos = $self->{"input_position"};
	my $line = $self->{"input_line"};
	my $regex = "[A-Za-z0-9]";
	my $bword;

	$bword = $self->find_word_bound($line, $pos, WORD_BEGINNING);

	# Delete whatever word we just found.
	substr($line, $bword, $pos - $bword) = '';

	# Update stuff...
	$self->{"input_line"} = $line;
	$self->{"input_position"} -= ($pos - $bword);

	$self->fix_inputline();
}

=pod

=item $sh->complete_word

This is called whenever the complete-word binding is triggered. See the
COMPLETION section below for how to write your own completion function.

=cut

sub complete_word {
	my $self = shift;
	my $pos = $self->{"input_position"};
	my $line = $self->{"input_line"};
	my $regex = "[A-Za-z0-9]";
	my $bword;
	my $complete;

	if (ref($self->{"completion_function"}) eq 'CODE') {
		my @matches;

	# Maintain some sort of state here if this is the first time we've 
	# hit complete_word() for this "scenario." What I mean is, we need to track
	# whether or not this user is hitting tab once or twice (or more) in the
	# same position.
RECHECK:
		if (!defined($self->{"completion"})) {
			$bword = $self->find_word_bound($line, $pos, WORD_BEGINNING | WORD_REGEX, '\S');
			$complete = substr($line,$bword,$pos - $bword);
			#$self->out("Complete: $complete");

			#$self->out("First time completing $complete");
			$self->{"completion"} = {
				"index" => 0,
				"original" => $complete,
				"pos" => $pos,
				"bword" => $bword,
				"line" => $line,
				"endpos" => $pos,
			};
		} else {
			$bword = $self->{"completion"}->{"bword"};
			$complete = substr($line,$bword,$pos - $bword);
		}

		# If we don't have any matches to check against...
		unless (defined($self->{"completion"}->{"matches"})) {
			@matches = 
				&{$self->{"completion_function"}}($line, $bword, $pos, $complete);
			@{$self->{"completion"}->{"matches"}} = @matches;
		} else {
			@matches = @{$self->{"completion"}->{"matches"}};
		}

		my $match = $matches[$self->{"completion"}->{"index"}];

		return unless (defined($match));

		#$self->out("Match: $match / " . $self->{"completion"}->{"index"} . " / " . @matches);

		$self->{"completion"}->{"index"}++;
		$self->{"completion"}->{"index"} = 0 if ($self->{"completion"}->{"index"} == scalar(@matches));

		substr($line, $bword, $pos - $bword) = $match;

		$self->{"completion"}->{"endpos"} = $pos;

		$pos = $bword + length($match);
		$self->{"input_position"} = $pos;
		$self->{"input_line"} = $line;

		$self->fix_inputline();

	}
}


# --------------------------------------------------------------------
# Helper functions

# Go from a position and find the beginning of the word we're on.
sub find_word_bound ($$$;$) {
	my $self = shift;
	my $line = shift;
	my $pos = shift;
	my $opts = shift || 0;
	my $regex = "[A-Za-z0-9]";
	my $bword;

	$regex = shift if ($opts & WORD_REGEX);

	# Mod? This is either -1 or +1 depending on if we're looking behind or
	# if we're looking ahead.
	my $mod = -1;
	$mod = 1 if ($opts & WORD_END);

	# What are we doing?
	# If we're in a word, go to the beginning of the word
	# If we're on a space, go to end of previous word.
	# If we're on a nonspace/nonword, go to beginning of nonword chars
	
	$bword = $pos - 1;

	# If we're at the end of the string, ignore all trailing whitespace.
	# unless WORD_ONLY is set.
	#out("
	if (($bword + 1 == $pos) && (! $opts & WORD_ONLY)) {
		$bword += $mod while (substr($line,$bword,1) =~ m/^\s$/);
	}

	# If we're not on an ALPHANUM, then we want to reverse the match.
	# that is, if we are:
	# "testing here hello .......there"
	#                           ^-- here
	# Then we want to delete (match) all the periods (nonalphanums)
	substr($regex, 1, 0) = "^" if (substr($line,$bword,1) !~ m/$regex/);

	# Back up until we hit the end of our "word"
	$bword += $mod while (substr($line,$bword,1) =~ m/$regex/ && $bword >= 0);

	# Whoops, one too far...
	$bword -= $mod;

	return $bword;
}

=pod

=back

=cut

1;
