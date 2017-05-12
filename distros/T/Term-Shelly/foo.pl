#!/usr/bin/perl

use Shelly;

my @COMMANDS = qw(help server login connect message disconnect hop);
my @WORDS = qw(hello how are you today fantasy rumble forward down fast);

my $sh = Term::Shelly->new();

$sh->out(
"This is a demo of Term::Shelly. It is designed to show you some of the
features of it. For this demo there is only a short number of features
available, more will appear later. You can do basic line editing (arrows move
around, backspace, ^W, tab completion, ^U, etc)","","The following commands can
be tab completed:
" . join(" ", @COMMANDS) . "
However, no commands actually do anything, this is jus tto demo the tab
completion system. The following words can be tab completed: 
" . join(" ", @WORDS)."
Commands must start with a / (forward slash) and be at the beginning of 
the line.");

$sh->{"completion_function"} = \&completer;


while (1) {
	$sh->do_one_loop();
}

sub completer {
	my ($line, $bword, $pos, $curword) = @_;

	my @matches;

	# Context-sensitive completion.
	#
	# Only complete commands if our current word begins on the 0th column
	# and starts with a / (slash)
	if (($bword == 0) && (substr($line,$bword,1) eq '/')) {
		# We want to complete a command...
		$word = substr($curword,1);
		@matches = map { "/$_" } grep(m/^\Q$word\E/i, @COMMANDS);
	} else {
		@matches = grep(m/\Q$curword\E/i, @WORDS);
	}

	return @matches;
}
