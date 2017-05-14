#!/usr/bin/perl -w

=head1 NAME

Quizzer::FrontEnd::Dialog - dialog FrontEnd

=cut

=head1 DESCRIPTION

This FrontEnd is for a user interface based on dialog, whiptail, or gdialog.
It will use whichever is available, but prefers to use whiptail if available.
It handles all the messy communication with thse programs.

It currently uses only whiptail of gdialog, because dialog lacks --defaultno.

=cut

=head1 METHODS

=cut
   
package Quizzer::FrontEnd::Dialog;
use Quizzer::FrontEnd::Tty;
use Quizzer::Level;
use Quizzer::Log ':all';
use Quizzer::Config;
use Text::Wrap qw(wrap $columns);
use IPC::Open3;
use strict;
use vars qw(@ISA);
@ISA=qw(Quizzer::FrontEnd::Tty);

my $VERSION='0.01';

=head2 new

Creates and returns a new FrontEnd::Dialog object. It will look to see if
whiptail, or dialog, or gdialog are available, in that order. To make it use
dialog, set FORCE_DIALOG in the environment. To make it use gdialog, set
FORCE_GDIALOG in the environment.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;

	$self->{interactive}=1;
	$self->{capb} = 'backup';

	# Autodetect if whiptail or dialog is available and set magic numbers.
	if (-x "/usr/bin/whiptail" && ! defined $ENV{FORCE_DIALOG} &&
	    ! defined $ENV{FORCE_GDIALOG}) {
		$self->{program}='whiptail';
		$self->{borderwidth}=5;
		$self->{borderheight}=6;
		$self->{spacer}=1;
		$self->{titlespacer}=10;
		$self->{columnspacer}=3;
	}
	elsif (-x "/usr/bin/dialog" && ! defined $ENV{FORCE_GDIALOG}) {
		$self->{program}='dialog';
		$self->{borderwidth}=7;
		$self->{borderheight}=6;
		$self->{spacer}=4;
		$self->{titlespacer}=4;
		$self->{columnspacer}=2;
	}
# Disabled until it supports --passwordbox
#	elsif (-x "/usr/bin/gdialog") {
#		$self->{program}='gdialog';
#		$self->{borderwidth}=5;
#		$self->{borderheight}=6;
#		$self->{spacer}=1;
#		$self->{titlespacer}=10;
#		$self->{columnspacer}=0;
#	}
	else {
		die "Neither whiptail nor dialog are installed, so the dialog based frontend cannot be used.";
#		die "None of whiptail, dialog, or gdialog is installed, so the dialog based frontend cannot be used.";
	}

	return $self;
}

=head2 sizetext

Dialog and whiptail have an annoying property of requiring you specify
their dimentions explicitly. This function handles doing that. Just pass in
the text that will be displayed in the dialog, and it will spit out new text,
formatted nicely, then the height for the dialog, and then the width for the
dialog.

=cut

sub sizetext {
	my $this=shift;
	my $text=shift;
	
	# Try to guess how many lines the text will take up in the dialog.
	# This is difficult because long lines are wrapped. So what I'll do
	# is pre-wrap the text and then just look at the number of lines it
	# takes up.
	$columns = $this->screenwidth - $this->borderwidth - $this->columnspacer;
	$text=wrap('', '', $text);
	my @lines=split(/\n/, $text);
	
	# Now figure out what's the longest line. Look at the title size too.
	my $window_columns=length($this->title) + $this->titlespacer;
	map { $window_columns=length if length > $window_columns } @lines;
	
	return $text, $#lines + 1 + $this->borderheight,
	       $window_columns + $this->borderwidth;
}

=head2 showtext

Pass this some text and it will display the text to the user in
a dialog. If the text is too long to fit in one dialog, it will use a
scrollable dialog.

=cut

sub showtext {
	my $this=shift;
	my $intext=shift;

	my $lines = $this->screenheight;
	my ($text, $height, $width)=$this->sizetext($intext);

	my @lines = split(/\n/, $text);
	my $num;
	my @args=('--msgbox', join("\n", @lines));
	if ($lines - 4 - $this->borderheight <= $#lines) {
		$num=$lines - 4 - $this->borderheight;
		if ($this->program eq 'whiptail') {
			# Whiptail can scroll text easily.
			push @args, '--scrolltext';
		}
		else {
			# Dialog has to use a temp file.
			my $name=Quizzer::Config::tmpdir."/dialog-tmp.$$";
			open(FH, ">$name") or die "$name: $!";
			print FH join("\n", @lines);
			close FH;
			@args=("--textbox", $name);
		}
	}
	else {
		$num=$#lines + 1;
	}
	$this->showdialog(@args, $num + $this->borderheight, $width);
	if ($args[0] eq '--textbox') {
		unlink $args[1];
	}
}

=head2 makeprompt

This is a helper function used by some dialog Elements. Pass it the Question
that is going to be displayed. It will use this to generate a prompt, using
both the short and long descriptions of the Question.

You can optionally pass in a second parameter: a number. This can be used to
tune howe many lines are free on the screen.

If the prompt is too large to fit on the screen, it will instead be displayed
immediatly, and the promnpt will be changed to just the short description.

The return value is identical to the return value of sizetext() run on the
generate prompt.

=cut

sub makeprompt {
	my $this=shift;
	my $question=shift;
	my $freelines=$this->screenheight - $this->borderheight + 1;
	$freelines += shift if @_;

	my ($text, $lines, $columns)=$this->sizetext(
		$question->extended_description."\n\n".
		$question->description
	);
	
	if ($lines > $freelines) {
		$this->showtext($question->extended_description);
		($text, $lines, $columns)=$this->sizetext($question->description);
	}
	
	return ($text, $lines, $columns);
}

=head2 showdialog

Displays a dialog. All parameters are passed to whiptail/dialog.

If called in a scalar context, returns whatever dialog outputs to stderr.
If called in a list context, returns the return code of dialog, then the
stderr output.

Note that the return code of dialog is examined, and if the user hit escape
or cancel, this frontend will assume they wanted to back up.

=cut

sub showdialog {
	my $this=shift;

	debug 2, "preparing to run dialog. Params are:" ,
		join(",", $this->program, @_);

	# Save stdout, stdin, the open3 below messes with them.
	use vars qw{*SAVEOUT *SAVEIN};
	open(SAVEOUT, ">&STDOUT") || die $!;
	open(SAVEIN, "<&STDIN") || die $!;

	# If warnings are enabled by $^W, they are actually printed to
	# stdout by IPC::Open3 and get stored in $stdout below! (I have no idea
	# why.) So they must be disabled.
	my $savew=$^W;
	$^W=0;
	
	my $pid = open3('<&STDIN', '>&STDOUT', \*ERRFH, $this->program, 
		'--backtitle', 'Quizzer - Copyright (C) 2002 Stefano Corsi, Mlx S.r.l - Madeinlinux',
		'--title', $this->title, @_);
	my $stderr;	
	while (<ERRFH>) {
		$stderr.=$_;
	}
	chomp $stderr;

	# Have to put the wait here to make sure $? is set properly.
	wait;
	$^W=$savew;
	use strict;

	# Restore stdout, stdin.
	open(STDOUT, ">&SAVEOUT") || die $!;
	open(STDIN, "<&SAVEIN") || die $!;

	# Now check dialog's return code to see if escape (-1) or
	# Cancel (1) were hit. If so, make a note that we should back up.
	#
	# To complicate things, a return code of 1 also means that yes was
	# selected from a yes/no dialog, so we must parse the parameters
	# to see if such a dialog was displayed.
	my $ret=$? >> 8;
	if ($ret == -1 || ($ret == 1 && join(' ', @_) !~ m/--yesno\s/)) {
		$this->backup(1);
	}
	if (wantarray) {
		return $ret, $stderr;
	}
	else {
		return $stderr;
	}
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
