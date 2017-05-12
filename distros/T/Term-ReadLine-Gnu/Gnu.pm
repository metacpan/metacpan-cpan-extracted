#
#	Gnu.pm --- The GNU Readline/History Library wrapper module
#
#	$Id: Gnu.pm 556 2016-11-03 14:24:45Z hayashi $
#
#	Copyright (c) 1996-2016 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.
#
#	Some of documentation strings in this file are cited from the
#	GNU Readline/History Library Manual.

package Term::ReadLine::Gnu;

=head1 NAME

Term::ReadLine::Gnu - Perl extension for the GNU Readline/History Library

=head1 SYNOPSIS

  use Term::ReadLine;	# Do not "use Term::ReadLine::Gnu;"
  $term = new Term::ReadLine 'ProgramName';
  while ( defined ($_ = $term->readline('prompt>')) ) {
    ...
  }

=head1 DESCRIPTION

=head2 Overview

This is an implementation of
L<Term::ReadLine|http://search.cpan.org/dist/Term-ReadLine/> using
L<the GNU ReadlineE<sol>History
Library|http://cnswww.cns.cwru.edu/php/chet/readline/rltop.html>.

For basic functions object oriented interface is provided. These are
described in the section L</"Standard Methods"> and
L</"C<Term::ReadLine::Gnu> Functions">.

This package also has the interface with the almost all functions and
variables which are documented in the GNU Readline/History Library
Manual.  They are documented in the section
L</"C<Term::ReadLine::Gnu> Functions">
and
L</"C<Term::ReadLine::Gnu>
Variables"> briefly.  For further details of the GNU Readline/History
Library, see L<GNU Readline Library
Manual|http://cnswww.cns.cwru.edu/php/chet/readline/readline.html> and
L<GNU History Library
Manual|http://cnswww.cns.cwru.edu/php/chet/readline/history.html>.

There are some C<Term::ReadLine::Gnu> original features.  They are
described in the section L</"C<Term::ReadLine::Gnu> Specific
Features">

The sample programs under F<eg/> directory and test programs under
F<t/> directory in L<the C<Term::ReadLine::Gnu> distribution|http://search.cpan.org/dist/Term-ReadLine-Gnu/> include
many examples of this module.

=head2 Standard Methods

These are standard methods defined by
L<Term::ReadLine|http://search.cpan.org/dist/Term-ReadLine/>.

=cut

use strict;
use warnings;
use Carp;
# use version TRG-1.22 for perl 5.7.x, or TRG-1.09 for older Perl
use 5.8.1;

# This module can't be loaded directly.
BEGIN {
    if (not defined $Term::ReadLine::VERSION) {
        croak <<END;
It is invalid to load Term::ReadLine::Gnu directly.  Please consult
the Term::ReadLine documentation for more information.
END
    }
}

{
    use Exporter ();
    use DynaLoader;

    our $VERSION = '1.35';		# update Gnu::XS::VERSION also.

    # Term::ReadLine::Gnu::AU makes a function in
    # `Term::ReadLine::Gnu::XS' as a method.
    # The namespace of Term::ReadLine::Gnu::AU is searched before ones
    # of other classes

    our @ISA = qw(Term::ReadLine::Gnu::AU Term::ReadLine::Stub
		  Exporter DynaLoader);

    our %EXPORT_TAGS = (
	prompt =>	[qw(RL_PROMPT_START_IGNORE RL_PROMPT_END_IGNORE)],
	match_type =>	[qw(NO_MATCH SINGLE_MATCH MULT_MATCH)],
	keymap_type =>	[qw(ISFUNC ISKMAP ISMACR)],
	undo_code =>	[qw(UNDO_DELETE UNDO_INSERT UNDO_BEGIN UNDO_END)],
	rl_state =>	[qw(RL_STATE_NONE RL_STATE_INITIALIZING
			    RL_STATE_INITIALIZED RL_STATE_TERMPREPPED
			    RL_STATE_READCMD RL_STATE_METANEXT
			    RL_STATE_DISPATCHING RL_STATE_MOREINPUT
			    RL_STATE_ISEARCH RL_STATE_NSEARCH
			    RL_STATE_SEARCH RL_STATE_NUMERICARG
			    RL_STATE_MACROINPUT RL_STATE_MACRODEF
			    RL_STATE_OVERWRITE RL_STATE_COMPLETING
			    RL_STATE_SIGHANDLER RL_STATE_UNDOING
			    RL_STATE_INPUTPENDING RL_STATE_TTYCSAVED
			    RL_STATE_CALLBACK RL_STATE_VIMOTION
			    RL_STATE_MULTIKEY RL_STATE_VICMDONCE
			    RL_STATE_CHARSEARCH RL_STATE_REDISPLAYING
			    RL_STATE_DONE)],
	);
    Exporter::export_ok_tags('prompt');
    Exporter::export_ok_tags('match_type');
    Exporter::export_ok_tags('keymap_type');
    Exporter::export_ok_tags('undo_code');
    Exporter::export_ok_tags('rl_state');

    bootstrap Term::ReadLine::Gnu $VERSION; # DynaLoader
}
require Term::ReadLine::Gnu::XS;

#	Global Variables

our($readline_version);

# Each variable in the GNU Readline Library is tied to an entry of
# this hash (%Attribs).  By accessing the hash entry, you can read
# and/or write the variable in the GNU Readline Library.  See the
# package definition of Term::ReadLine::Gnu::Var and following code
# for further details.

# Normal (non-tied) entries
our %Attribs  = (
    MinLength => 1,
    do_expand => 0,
    completion_word => [],
    term_set => ['', '', '', ''],
    );
our %Features = (
    appname => 1, minline => 1, autohistory => 1,
    getHistory => 1, setHistory => 1, addHistory => 1,
    readHistory => 1, writeHistory => 1,
    preput => 1, attribs => 1, newTTY => 1,
    tkRunning => Term::ReadLine::Stub->Features->{'tkRunning'},
    ornaments => Term::ReadLine::Stub->Features->{'ornaments'},
    stiflehistory => 1,
    );

#
#	GNU Readline/History Library constant definition
#	These are included in @EXPORT_OK.

# I can define these variables in XS code to use the value defined in
# readline.h, etc.  But it needs some calling convention change and
# will cause compatiblity problem. I hope the definition of these
# constant value will not be changed.

# for non-printing characters in prompt string
sub RL_PROMPT_START_IGNORE	{ "\001"; }
sub RL_PROMPT_END_IGNORE	{ "\002"; }

# for rl_filename_quoting_function
sub NO_MATCH	 { 0; }
sub SINGLE_MATCH { 1; }
sub MULT_MATCH   { 2; }

# for rl_generic_bind, rl_function_of_keyseq
sub ISFUNC	{ 0; }
sub ISKMAP	{ 1; }
sub ISMACR	{ 2; }

# for rl_add_undo
sub UNDO_DELETE	{ 0; }
sub UNDO_INSERT	{ 1; }
sub UNDO_BEGIN	{ 2; }
sub UNDO_END	{ 3; }

# for rl_readline_state which was implemented since 4.2
sub RL_STATE_NONE		{ 0x00000; } # no state; before first call
sub RL_STATE_INITIALIZING	{ 0x00001; } # initializing
sub RL_STATE_INITIALIZED	{ 0x00002; } # initialization done
sub RL_STATE_TERMPREPPED	{ 0x00004; } # terminal is prepped
sub RL_STATE_READCMD		{ 0x00008; } # reading a command key
sub RL_STATE_METANEXT		{ 0x00010; } # reading input after ESC
sub RL_STATE_DISPATCHING	{ 0x00020; } # dispatching to a command
sub RL_STATE_MOREINPUT		{ 0x00040; } # reading more input in a command function
sub RL_STATE_ISEARCH		{ 0x00080; } # doing incremental search
sub RL_STATE_NSEARCH		{ 0x00100; } # doing non-inc search
sub RL_STATE_SEARCH		{ 0x00200; } # doing a history search
sub RL_STATE_NUMERICARG		{ 0x00400; } # reading numeric argument
sub RL_STATE_MACROINPUT		{ 0x00800; } # getting input from a macro
sub RL_STATE_MACRODEF		{ 0x01000; } # defining keyboard macro
sub RL_STATE_OVERWRITE		{ 0x02000; } # overwrite mode
sub RL_STATE_COMPLETING		{ 0x04000; } # doing completion
sub RL_STATE_SIGHANDLER		{ 0x08000; } # in readline sighandler
sub RL_STATE_UNDOING		{ 0x10000; } # doing an undo
sub RL_STATE_INPUTPENDING	{ 0x02_0000; } # rl_execute_next called
sub RL_STATE_TTYCSAVED		{ 0x04_0000; } # tty special chars saved [5.0]
sub RL_STATE_CALLBACK		{ 0x08_0000; } # using the callback interface [5.1]
sub RL_STATE_VIMOTION		{ 0x10_0000; } # reading vi motion arg [5.1]
sub RL_STATE_MULTIKEY		{ 0x20_0000; } # reading multiple-key command [5.1]
sub RL_STATE_VICMDONCE		{ 0x40_0000; } # entered vi command mode at least once [5.1]
sub RL_STATE_CHARSEARCH		{ 0x80_0000; } # vi mode char search [7.0]
sub RL_STATE_REDISPLAYING	{	       # updating terminal display [6.1]
    $readline_version < 0x0700 ? 0x80_0000 : 0x100_0000;
}
sub RL_STATE_DONE {			       # done; accepted line
    $readline_version < 0x0501 ? 0x8_0000 : 
	($readline_version < 0x0601 ? 0x80_0000 :
	 ($readline_version < 0x0700 ? 0x100_0000 : 0x200_0000));
}

#
#	Methods Definition
#

=over 4

=item C<ReadLine>

returns the actual package that executes the commands. If
this package is being used, C<Term::ReadLine::Gnu> is returned.

=cut

sub ReadLine { 'Term::ReadLine::Gnu'; }

=item C<new(NAME,[IN,OUT])>

returns the handle for subsequent calls to following functions.
Argument is the name of the application.  Optionally can be followed
by two arguments for C<IN> and C<OUT> file handles. These arguments
should be globs.

=cut

# The origin of this function is Term::ReadLine::Perl.pm by Ilya Zakharevich.
sub new {
    my $this = shift;		# Package
    my $class = ref($this) || $this;

    my $name = shift;

    my $self = \%Attribs;
    bless $self, $class;

    # set rl_readline_name before .inputrc is read in rl_initialize()
    $Attribs{readline_name} = $name;

    # some version of Perl cause segmentation fault, if XS module
    # calls setenv() before the 1st assignment to $ENV{}.
    $ENV{_TRL_DUMMY} = '';

    # UTF-8 condition conpatible with Term:ReadLine
    $Attribs{utf8_mode} ||= ${^UNICODE} & 1 || defined ${^ENCODING};
    #printf "\${^UNICODE}: 0x%X, ", ${^UNICODE};
    #print "\${^ENCODING}: ", defined ${^ENCODING} ? 'defined' : 'undef', "\n";
    
    # set tty before calling rl_initialize() not to output some
    # charactores to STDIO.
    # https://rt.cpan.org/Ticket/Display.html?id=96569
    if (!@_) {
	my ($in, $out) = $self->findConsole();
	open(my $IN,"<$in")   || croak "Cannot open $in for read";
	open(my $OUT,">$out") || croak "Cannot open $out for write";
	if ($Attribs{utf8_mode}) {
	    binmode $IN,  ':encoding(UTF-8)'; # not necessary
	    binmode $OUT, ':encoding(UTF-8)';
	}
	$self->newTTY($IN, $OUT);
    } else {
	# enable UTF-8 mode if input stream has the utf8 layer.
	my @layers = PerlIO::get_layers($_[0]);
	$Attribs{utf8_mode} ||= ($layers[$#layers] eq 'utf8');
    
	$self->newTTY(@_);
    }

    # initialize the GNU Readline Library and termcap library
    # This calls tgetent().
    $self->initialize();

    # enable ornaments to be compatible with perl5.004_05(?)
    # This calls tgetstr().
    $self->ornaments(1) unless ($ENV{PERL_RL} and $ENV{PERL_RL} =~ /\bo\w*=0/);

    # keep rl_readline_version value for efficiency
    $readline_version = $Attribs{readline_version};

    $self;
}

sub DESTROY {}

=item C<readline(PROMPT[,PREPUT])>

gets an input line, with actual C<GNU Readline> support.  Trailing
newline is removed.  Returns C<undef> on C<EOF>.  C<PREPUT> is an
optional argument meaning the initial value of input.

The optional argument C<PREPUT> is granted only if the value C<preput>
is in C<Features>.

C<PROMPT> may include some escape sequences.  Use
C<RL_PROMPT_START_IGNORE> to begin a sequence of non-printing
characters, and C<RL_PROMPT_END_IGNORE> to end the sequence.

=cut

# to peacify -w
$Term::ReadLine::registered = $Term::ReadLine::registered;

sub readline {			# should be ReadLine
    my $self = shift;
    my ($prompt, $preput) = @_;

    # A contributed fix for Perl debugger
    # make sure the outstream fd inside the readline library is
    # in sync (see http://bugs.debian.org/236018)
    # This is not a real fix but left for system where this fix works.
    # Here is the real fix for perl5db.pl.
    # https://rt.perl.org/Public/Bug/Display.html?id=121456
    $Attribs{outstream} = $Attribs{outstream};

    # ornament support (now prompt only)
    $prompt = ${$Attribs{term_set}}[0] . $prompt . ${$Attribs{term_set}}[1];

    # `completion_function' support for compatibility with
    # Term:ReadLine::Perl.  Prefer $completion_entry_function, since a
    # program which uses $completion_entry_function should know
    # Term::ReadLine::Gnu and have better completion function using
    # the variable.
    $Attribs{completion_entry_function} = $Attribs{_trp_completion_function}
	if (!defined $Attribs{completion_entry_function}
	    && defined $Attribs{completion_function});

    # TkRunning support
    if (not $Term::ReadLine::registered and $Term::ReadLine::toloop
	and defined &Tk::DoOneEvent) {
	$self->register_Tk;
	$Attribs{getc_function} = $Attribs{Tk_getc};
    }

    # call readline()
    my $line;
    if (defined $preput) {
	my $saved_startup_hook = $Attribs{startup_hook};
	$Attribs{startup_hook} = sub {
	    $self->rl_insert_text($preput);
	    &$saved_startup_hook
		if defined $saved_startup_hook;
	};
	$line = $self->rl_readline($prompt);
	$Attribs{startup_hook} = $saved_startup_hook;
    } else {
	$line = $self->rl_readline($prompt);
    }
    return undef unless defined $line;

    # history expansion
    if ($Attribs{do_expand}) {
	my $result;
	($result, $line) = $self->history_expand($line);
	my $outstream = $Attribs{outstream};
	print $outstream "$line\n" if ($result);

	# return without adding line into history
	if ($result < 0 || $result == 2) {
	    return '';		# don't return `undef' which means EOF.
	}
    }

    # add to history buffer
    $self->add_history($line)
	if (defined $self->{MinLength} && $self->{MinLength} > 0
	    && length($line) >= $self->{MinLength});

    return $line;
}

=item C<AddHistory(LINE1, LINE2, ...)>

adds the lines to the history of input, from where it can be used if
the actual C<readline> is present.

=cut

#use vars '*addhistory';
*addhistory = \&AddHistory;	# for backward compatibility

sub AddHistory {
    my $self = shift;
    foreach (@_) {
	$self->add_history($_);
    }
}

=item C<IN>, C<OUT>

return the file handles for input and output or C<undef> if
C<readline> input and output cannot be used for Perl.

=cut

sub IN  { $Attribs{instream}; }
sub OUT { $Attribs{outstream}; }

=item C<MinLine([MAX])>

If argument C<MAX> is specified, it is an advice on minimal size of
line to be included into history.  C<undef> means do not include
anything into history.  Returns the old value.

=cut

sub MinLine {
    my $self = shift;
    my $old_minlength = $self->{MinLength};
    $self->{MinLength} = shift;
    $old_minlength;
}

=item C<findConsole>

returns an array with two strings that give most appropriate names for
files for input and output using conventions C<"E<lt>$in">, C<"E<gt>$out">.

=cut

# findConsole is defined in ReadLine.pm.

=item C<Attribs>

returns a reference to a hash which describes internal configuration
(variables) of the package.  Names of keys in this hash conform to
standard conventions with the leading C<rl_> stripped.

See section L</"C<Term::ReadLine::Gnu> Variables"> for supported variables.

=cut

sub Attribs { \%Attribs; }

=item C<Features>

Returns a reference to a hash with keys being features present in
current implementation. Several optional features are used in the
minimal interface: C<appname> should be present if the first argument
to C<new> is recognized, and C<minline> should be present if
C<MinLine> method is not dummy.  C<autohistory> should be present if
lines are put into history automatically (maybe subject to
C<MinLine>), and C<addHistory> if C<AddHistory> method is not dummy. 
C<preput> means the second argument to C<readline> method is processed.
C<getHistory> and C<setHistory> denote that the corresponding methods are 
present. C<tkRunning> denotes that a Tk application may run while ReadLine
is getting input.

=cut

sub Features { \%Features; }

=item C<tkRunning>

makes Tk event loop run when waiting for user input (i.e., during
C<readline> method).

=cut

# tkRunning is defined in ReadLine.pm.

=item C<event_loop>

See the description of C<event_loop> on
L<Term::ReadLine|http://search.cpan.org/dist/Term-ReadLine/>.

=item C<ornaments>

makes the command line stand out by using termcap data.  The argument
to C<ornaments> should be 0, 1, or a string of a form
C<"aa,bb,cc,dd">.  Four components of this string should be names of
I<terminal capacities>, first two will be issued to make the prompt
standout, last two to make the input line standout.

=cut

sub ornaments {
    my $self = shift;
    return Term::ReadLine::Gnu::XS::ornaments(@_);
}

=item C<newTTY>

takes two arguments which are input filehandle and output filehandle.
Switches to use these filehandles.

=cut

# used by a program (ex. perldb5.pl) who changes input/output stream.
sub newTTY {
    my ($self, $in, $out) = @_;

    # borrowed from Term/ReadLine.pm
    my $sel = select($out);
    $| = 1;			# for DB::OUT
    select($sel);

    $Attribs{instream}  = $in;
    $Attribs{outstream} = $out;
}

=item C<enableUTF8>

Enables UTF-8 support.

If STDIN is in UTF-8 by the C<-C> command-line switch or
C<PERL_UNICODE> environment variable, or C<IN> file handle has C<utf8>
IO layer, then UTF-8 support is also enabled.  In other cases you need
this C<enableUTF8> method.

This is an original method of C<Term::ReadLine:Gnu>.

=cut

sub enableUTF8 {
    my $self = shift;
    $Attribs{utf8_mode} = 1;
    binmode $self->IN,  ':encoding(UTF-8)'; # not necessary
    binmode $self->OUT, ':encoding(UTF-8)';
}

=back

=cut

# documented later
sub CallbackHandlerInstall {
    my $self = shift;
    my ($prompt, $lhandler) = @_;

    $Attribs{_callback_handler} = $lhandler;

    # ornament support (now prompt only)
    $prompt = ${$Attribs{term_set}}[0] . $prompt . ${$Attribs{term_set}}[1];

    $Attribs{completion_entry_function} = $Attribs{_trp_completion_function}
	if (!defined $Attribs{completion_entry_function}
	    && defined $Attribs{completion_function});

    $self->rl_callback_handler_install($prompt,
				       \&Term::ReadLine::Gnu::XS::_ch_wrapper);
}


#
#	Additional Supported Methods
#

# Documentation is after '__END__' for efficiency.

# for backward compatibility
#use vars qw(*AddDefun *BindKey *UnbindKey *ParseAndBind *StifleHistory);
*AddDefun = \&add_defun;
*BindKey = \&bind_key;
*UnbindKey = \&unbind_key;
*ParseAndBind = \&parse_and_bind;
*StifleHistory = \&stifle_history;

sub SetHistory {
    my $self = shift;
    $self->clear_history();
    $self->AddHistory(@_);
}

sub GetHistory {
    my $self = shift;
    $self->history_list();
}

sub ReadHistory {
    my $self = shift;
    ! $self->read_history_range(@_);
}

sub WriteHistory {
    my $self = shift;
    ! $self->write_history(@_);
}

#
#	Access Routines for GNU Readline/History Library Variables
#
package Term::ReadLine::Gnu::Var;
use Carp;
use strict;
use warnings;
our %_rl_vars;

%_rl_vars
    = (
       rl_line_buffer				=> ['S', 0],
       rl_prompt				=> ['S', 1],
       rl_library_version			=> ['S', 2],
       rl_terminal_name				=> ['S', 3],
       rl_readline_name				=> ['S', 4],
       rl_basic_word_break_characters		=> ['S', 5],
       rl_basic_quote_characters		=> ['S', 6],
       rl_completer_word_break_characters	=> ['S', 7],
       rl_completer_quote_characters		=> ['S', 8],
       rl_filename_quote_characters		=> ['S', 9],
       rl_special_prefixes			=> ['S', 10],
       history_no_expand_chars			=> ['S', 11],
       history_search_delimiter_chars		=> ['S', 12],
       rl_executing_macro			=> ['S', 13], # GRL 4.2
       history_word_delimiters			=> ['S', 14], # GRL 4.2
       rl_display_prompt			=> ['S', 15], # GRL 6.0
       rl_executing_keyseq			=> ['S', 16], # GRL 6.3

       rl_point					=> ['I', 0],
       rl_end					=> ['I', 1],
       rl_mark					=> ['I', 2],
       rl_done					=> ['I', 3],
       rl_pending_input				=> ['I', 4],
       rl_completion_query_items		=> ['I', 5],
       rl_completion_append_character		=> ['C', 6],
       rl_ignore_completion_duplicates		=> ['I', 7],
       rl_filename_completion_desired		=> ['I', 8],
       rl_filename_quoting_desired		=> ['I', 9],
       rl_inhibit_completion			=> ['I', 10],
       history_base				=> ['I', 11],
       history_length				=> ['I', 12],
       history_max_entries			=> ['I', 13],
       max_input_history			=> ['I', 13], # before GRL 4.2
       history_write_timestamps			=> ['I', 14], # GRL 5.0
       history_expansion_char			=> ['C', 15],
       history_subst_char			=> ['C', 16],
       history_comment_char			=> ['C', 17],
       history_quotes_inhibit_expansion		=> ['I', 18],
       rl_erase_empty_line			=> ['I', 19], # GRL 4.0
       rl_catch_signals				=> ['I', 20], # GRL 4.0
       rl_catch_sigwinch			=> ['I', 21], # GRL 4.0
       rl_already_prompted			=> ['I', 22], # GRL 4.1
       rl_num_chars_to_read			=> ['I', 23], # GRL 4.1
       rl_dispatching				=> ['I', 24], # GRL 4.2
       rl_gnu_readline_p			=> ['I', 25], # GRL 4.1
       rl_readline_state			=> ['I', 26], # GRL 4.2
       rl_explicit_arg				=> ['I', 27], # GRL 4.2
       rl_numeric_arg				=> ['I', 28], # GRL 4.2
       rl_editing_mode				=> ['I', 29], # GRL 4.2
       rl_attempted_completion_over		=> ['I', 30], # GRL 4.2
       rl_completion_type			=> ['I', 31], # GRL 4.2
       rl_readline_version			=> ['I', 32], # GRL 4.2a
       rl_completion_suppress_append		=> ['I', 33], # GRL 4.3
       rl_completion_quote_character		=> ['C', 34], # GRL 5.0
       rl_completion_suppress_quote		=> ['I', 35], # GRL 5.0
       rl_completion_found_quote		=> ['I', 36], # GRL 5.0
       rl_completion_mark_symlink_dirs		=> ['I', 37], # GRL 4.3
       rl_prefer_env_winsize			=> ['I', 38], # GRL 5.1
       rl_sort_completion_matches		=> ['I', 39], # GRL 6.0
       rl_completion_invoking_key		=> ['C', 40], # GRL 6.0
       rl_executing_key				=> ['I', 41], # GRL 6.3
       rl_key_sequence_length			=> ['I', 42], # GRL 6.3
       rl_change_environment			=> ['I', 43], # GRL 6.3
       rl_persistent_signal_handlers		=> ['I', 44], # GRL 7.0
       utf8_mode				=> ['I', 45], # internal

       rl_startup_hook				=> ['F', 0],
       rl_event_hook				=> ['F', 1],
       rl_getc_function				=> ['F', 2],
       rl_redisplay_function			=> ['F', 3],
       rl_completion_entry_function		=> ['F', 4],
       rl_attempted_completion_function		=> ['F', 5],
       rl_filename_quoting_function		=> ['F', 6],
       rl_filename_dequoting_function		=> ['F', 7],
       rl_char_is_quoted_p			=> ['F', 8],
       rl_ignore_some_completions_function	=> ['F', 9],
       rl_directory_completion_hook		=> ['F', 10],
       history_inhibit_expansion_function	=> ['F', 11],
       rl_pre_input_hook			=> ['F', 12], # GRL 4.0
       rl_completion_display_matches_hook	=> ['F', 13], # GRL 4.0
       rl_completion_word_break_hook		=> ['F', 14], # GRL 5.0
       rl_prep_term_function			=> ['F', 15], # GRL 4.2
       rl_deprep_term_function			=> ['F', 16], # GRL 4.2
       rl_directory_rewrite_hook		=> ['F', 17], # GRL 4.2
       rl_filename_rewrite_hook			=> ['F', 18], # GRL 6.1
       rl_signal_event_hook			=> ['F', 19], # GRL 6.3
       rl_input_available_hook			=> ['F', 20], # GRL 6.3
       rl_filename_stat_hook			=> ['F', 21], # GRL 6.3

       rl_instream				=> ['IO', 0],
       rl_outstream				=> ['IO', 1],

       rl_executing_keymap			=> ['K', 0],
       rl_binding_keymap			=> ['K', 1],

       rl_last_func                             => ['LF', 0],
      );

my @stream;

sub TIESCALAR {
    my $class = shift;
    my $name = shift;
    return bless \$name, $class;
}

sub FETCH {
    my $self = shift;
    confess "wrong type" unless ref $self;

    my $name = $$self;
    if (! defined $_rl_vars{$name}) {
	confess "Term::ReadLine::Gnu::Var::FETCH: Unknown variable name `$name'\n";
	return undef ;
    }

    my ($type, $id) = @{$_rl_vars{$name}};
    if ($type eq 'S') {
	return _rl_fetch_str($id);
    } elsif ($type eq 'I') {
	return _rl_fetch_int($id);
    } elsif ($type eq 'C') {
	return chr(_rl_fetch_int($id));
    } elsif ($type eq 'F') {
	return _rl_fetch_function($id);
    } elsif ($type eq 'IO') {
	# STORE was called in new() before coming here
	return $stream[$id];
    } elsif ($type eq 'K') {
	return _rl_fetch_keymap($id);
    } elsif ($type eq 'LF') {
        return _rl_fetch_last_func();
    } else {
	carp "Term::ReadLine::Gnu::Var::FETCH: Illegal type `$type'\n";
	return undef;
    }
}

sub STORE {
    my $self = shift;
    confess "wrong type" unless ref $self;

    my $name = $$self;
    if (! defined $_rl_vars{$name}) {
	confess "Term::ReadLine::Gnu::Var::STORE: Unknown variable name `$name'\n";
	return undef ;
    }

    my $value = shift;
    my ($type, $id) = @{$_rl_vars{$name}};
    if ($type eq 'S') {
	if ($name eq 'rl_line_buffer') {
	    return _rl_store_rl_line_buffer($value);
	} else {
	    return _rl_store_str($value, $id);
	}
    } elsif ($type eq 'I') {
	return _rl_store_int($value, $id);
    } elsif ($type eq 'C') {
	return chr(_rl_store_int(ord($value), $id));
    } elsif ($type eq 'F') {
	return _rl_store_function($value, $id);
    } elsif ($type eq 'IO') {
	_rl_store_iostream($value, $id);
	# _rl_store_iostream() calls PerlIO_findFILE().  It pushes the
	# 'stdio' layer on perl 5.10 and later. We must pop the stdio
	# layer.
	#   https://rt.cpan.org/Ticket/Display.html?id=59832
	# But we must pop the 'stdio' layer only when utf8 layer is
	# included for remote debugging.
	#   https://rt.cpan.org/Ticket/Display.html?id=110121
	if ($] >= 5.010) {
	    my @layers = PerlIO::get_layers($value);
	    if ((grep /^utf8$/, @layers) > 0 && $layers[$#layers] eq 'stdio') {
		binmode($value,  ":pop");
	    }
	}
	return $stream[$id] = $value;
    } elsif ($type eq 'K' || $type eq 'LF') {
	carp "Term::ReadLine::Gnu::Var::STORE: read only variable `$name'\n";
	return undef;
    } else {
	carp "Term::ReadLine::Gnu::Var::STORE: Illegal type `$type'\n";
	return undef;
    }
}

package Term::ReadLine::Gnu;
use Carp;
use strict;
use warnings;

#
#	set value of %Attribs
#

#	Tie all Readline/History variables
foreach (keys %Term::ReadLine::Gnu::Var::_rl_vars) {
    my $name;
    ($name = $_) =~ s/^rl_//;	# strip leading `rl_'
    tie $Attribs{$name},  'Term::ReadLine::Gnu::Var', $_;
}

#	add reference to some functions
{
    my ($name, $fname);
    no strict 'refs';		# allow symbolic reference
    map {
	($name = $_) =~ s/^rl_//; # strip leading `rl_'
	$fname = 'Term::ReadLine::Gnu::XS::' . $_;
	$Attribs{$name} = \&$fname; # symbolic reference
    } qw(rl_getc
	 rl_redisplay
	 rl_callback_read_char
	 rl_display_match_list
	 rl_filename_completion_function
	 rl_username_completion_function
	 list_completion_function
         _trp_completion_function);
    # auto-splited subroutines cannot be processed in the map loop above
    use strict 'refs';
    $Attribs{shadow_redisplay} = \&Term::ReadLine::Gnu::XS::shadow_redisplay;
    $Attribs{Tk_getc} = \&Term::ReadLine::Gnu::XS::Tk_getc;
    $Attribs{list_completion_function} = \&Term::ReadLine::Gnu::XS::list_completion_function;
}

package Term::ReadLine::Gnu::AU;
use Carp;
no strict qw(refs vars);
use warnings;

sub AUTOLOAD {
    { $AUTOLOAD =~ s/.*:://; }	# preserve match data
    my $name;
    if (exists $Term::ReadLine::Gnu::XS::{"rl_$AUTOLOAD"}) {
	$name = "Term::ReadLine::Gnu::XS::rl_$AUTOLOAD";
    } elsif (exists $Term::ReadLine::Gnu::XS::{"$AUTOLOAD"}) {
	$name = "Term::ReadLine::Gnu::XS::$AUTOLOAD";
    } else {
	croak "Cannot do `$AUTOLOAD' in Term::ReadLine::Gnu";
    }
    no warnings 'redefine';	# Why is this line necessary ???
    *$AUTOLOAD = sub { shift; &$name(@_); };
    goto &$AUTOLOAD;
}
1;
__END__


=head2 C<Term::ReadLine::Gnu> Functions

All these GNU Readline/History Library functions supported are callable via
method interface and have names which conform to standard conventions
with the leading C<rl_> stripped.  For example C<rl_foo()>
function is called as C<$term-E<gt>foo()>.

The titles of the following sections are same as the titles of the
corresponding sections in the "Programming with GNU Readline" section
in the L<GNU Readline Library
Manual|http://cnswww.cns.cwru.edu/php/chet/readline/readline.html>.
Refer them for further details.

Although it is preferred to use method interface, most methods have
lower level functions in
C<Term::ReadLine::Gnu::XS> package.  To use them a full qualified name
is required.

=head3 Basic Behavior

The function C<readline()> prints a prompt and then reads and returns
a single line of text from the user.

	$_ = $term->readline('Enter a line: ');

You can change key-bindings using C<bind_key(KEY, FUNCTION [,MAP])>
function.  The first argument, C<KEY>, is the character that you want
bind.  The second argument, C<FUNCTION>, is the function to call when
C<KEY> is pressed.  The C<FUNCTION> can be a reference to a Perl
function (see L</"Custom Functions">) or a "named function" named by
C<add_defun()> function or commands described in the "Bindable
Readline Commands" section in the L<GNU Readline Library
Manual|http://cnswww.cns.cwru.edu/php/chet/readline/readline.html>.

	$term->bind_key(ord "\ci, 'tab-insert');

The above example binds Control-I to the 'tab-insert' command.

=head3 Custom Functions

You can write new functions using Perl.  The calling sequence for a
command foo looks like

	sub foo ($count, $key) { ... }

where C<$count> is the numeric argument (or 1 if defaulted) and
C<$key> is the key that invoked this function.

Here is an example;

	sub reverse_line {		# reverse a whole line
	    my($count, $key) = @_;	# ignored in this sample function
    	
	    $t->modifying(0, $a->{end}); # save undo information
	    $a->{line_buffer} = reverse $a->{line_buffer};
	}

See the "Writing a New Function" section in the L<GNU Readline Library
Manual|http://cnswww.cns.cwru.edu/php/chet/readline/readline.html> for
further details.

=head3 Readline Convenience Functions

=head4 Naming a Function

=over 4

=item C<add_defun(NAME, FUNCTION [,KEY=-1])>

Add name to a Perl function C<FUNCTION>.  If optional argument C<KEY>
is specified, bind it to the C<FUNCTION>.  Returns reference to
C<FunctionPtr>.

  Example:
	# name `reverse-line' to a function reverse_line(),
	# and bind it to "\C-t"
	$term->add_defun('reverse-line', \&reverse_line, ord "\ct");

=back

=head4 Selecting a Keymap

=over 4

=item C<make_bare_keymap>

	Keymap	rl_make_bare_keymap()

=item C<copy_keymap(MAP)>

	Keymap	rl_copy_keymap(Keymap|str map)

=item C<make_keymap>

	Keymap	rl_make_keymap()

=item C<discard_keymap(MAP)>

	Keymap	rl_discard_keymap(Keymap|str map)

=item C<free_keymap(MAP)>

	void	rl_free_keymap(Keymap|str map)

=item C<get_keymap>

	Keymap	rl_get_keymap()

=item C<set_keymap(MAP)>

	Keymap	rl_set_keymap(Keymap|str map)

=item C<get_keymap_by_name(NAME)>

	Keymap	rl_get_keymap_by_name(str name)

=item C<get_keymap_name(MAP)>

	str	rl_get_keymap_name(Keymap map)

=back

=head4 Binding Keys

=over 4

=item C<bind_key(KEY, FUNCTION [,MAP])>

	int	rl_bind_key(int key, FunctionPtr|str function,
			    Keymap|str map = rl_get_keymap())

Bind C<KEY> to the C<FUNCTION>.  C<FUNCTION> is the name added by the
C<add_defun> method.  If optional argument C<MAP> is specified, binds
in C<MAP>.  Returns non-zero in case of error.

=item C<bind_key_if_unbound(KEY, FUNCTION [,MAP])>

	int	rl_bind_key_if_unbound(int key, FunctionPtr|str function,
			    	       Keymap|str map = rl_get_keymap()) # GRL 5.0

=item C<unbind_key(KEY [,MAP])>

	int	rl_unbind_key(int key, Keymap|str map = rl_get_keymap())

Bind C<KEY> to the null function.  Returns non-zero in case of error.

=item C<unbind_function(FUNCTION [,MAP])>

	int	rl_unbind_function(FunctionPtr|str function,
				   Keymap|str map = rl_get_keymap())

=item C<unbind_command(COMMAND [,MAP])>

	int	rl_unbind_command(str command,
				  Keymap|str map = rl_get_keymap())

=item C<bind_keyseq(KEYSEQ, FUNCTION [,MAP])>

	int	rl_bind_keyseq(str keyseq, FunctionPtr|str function,
			       Keymap|str map = rl_get_keymap()) # GRL 5.0

=item C<set_key(KEYSEQ, FUNCTION [,MAP])>

	int	rl_set_key(str keyseq, FunctionPtr|str function,
			   Keymap|str map = rl_get_keymap())	# GRL 4.2

=item C<bind_keyseq_if_unbound(KEYSEQ, FUNCTION [,MAP])>

	int	rl_bind_keyseq_if_unbound(str keyseq, FunctionPtr|str function,
					  Keymap|str map = rl_get_keymap()) # GRL 5.0

=item C<generic_bind(TYPE, KEYSEQ, DATA, [,MAP])>

	int	rl_generic_bind(int type, str keyseq,
				FunctionPtr|Keymap|str data,
				Keymap|str map = rl_get_keymap())

=item C<parse_and_bind(LINE)>

	void	rl_parse_and_bind(str line)

Parse C<LINE> as if it had been read from the F<~/.inputrc> file and
perform any key bindings and variable assignments found.  For further
detail see L<GNU Readline Library
Manual|http://cnswww.cns.cwru.edu/php/chet/readline/readline.html>.

=item C<read_init_file([FILENAME])>

	int	rl_read_init_file(str filename = '~/.inputrc')

=back

=head4 Associating Function Names and Bindings

=over 4

=item C<named_function(NAME)>

	FunctionPtr rl_named_function(str name)

=item C<get_function_name(FUNCTION)>

	str	rl_get_function_name(FunctionPtr function)	# TRG original

=item C<function_of_keyseq(KEYSEQ [,MAP])>

	(FunctionPtr|Keymap|str data, int type)
		rl_function_of_keyseq(str keyseq,
				      Keymap|str map = rl_get_keymap())

=item C<invoking_keyseqs(FUNCTION [,MAP])>

	(@str)	rl_invoking_keyseqs(FunctionPtr|str function,
				    Keymap|str map = rl_get_keymap())

=item C<function_dumper([READABLE])>

	void	rl_function_dumper(int readable = 0)

=item C<list_funmap_names>

	void	rl_list_funmap_names()

=item C<funmap_names>

	(@str)	rl_funmap_names()

=item C<add_funmap_entry(NAME, FUNCTION)>

	int	rl_add_funmap_entry(char *name, FunctionPtr|str function)

=back

=head4 Allowing Undoing

=over 4

=item C<begin_undo_group>

	int	rl_begin_undo_group()

=item C<end_undo_group>

	int	rl_end_undo_group()

=item C<add_undo(WHAT, START, END, TEXT)>

	int	rl_add_undo(int what, int start, int end, str text)

=item C<free_undo_list>

	void	rl_free_undo_list()

=item C<do_undo>

	int	rl_do_undo()

=item C<modifying([START [,END]])>

	int	rl_modifying(int start = 0, int end = rl_end)

=back

=head4 Redisplay

=over 4

=item C<redisplay>

	void	rl_redisplay()

=item C<forced_update_display>

	int	rl_forced_update_display()

=item C<on_new_line>

	int	rl_on_new_line()

=item C<on_new_line_with_prompt>

	int	rl_on_new_line_with_prompt()			# GRL 4.1

=item C<clear_visible_line()>

	int	rl_clear_visible_line()				# GRL 7.0

=item C<reset_line_state>

	int	rl_reset_line_state()

=item C<crlf>

	int	rl_crlf()

=item C<show_char(C)>

	int	rl_show_char(int c)

=item C<message(FMT[, ...])>

	int	rl_message(str fmt, ...)

=item C<clear_message>

	int	rl_clear_message()

=item C<save_prompt>

	void	rl_save_prompt()

=item C<restore_prompt>

	void	rl_restore_prompt()

=item C<expand_prompt(PROMPT)>

	int	rl_expand_prompt(str prompt)

=item C<set_prompt(PROMPT)>

	int	rl_set_prompt(const str prompt)			# GRL 4.2

=back

=head4 Modifying Text

=over 4

=item C<insert_text(TEXT)>

	int	rl_insert_text(str text)

=item C<delete_text([START [,END]])>

	int	rl_delete_text(int start = 0, int end = rl_end)

=item C<copy_text([START [,END]])>

	str	rl_copy_text(int start = 0, int end = rl_end)

=item C<kill_text([START [,END]])>

	int	rl_kill_text(int start = 0, int end = rl_end)

=item C<push_macro_input(MACRO)>

	int	rl_push_macro_input(str macro)

=back

=head4 Character Input

=over 4

=item C<read_key>

	int	rl_read_key()

=item C<getc(STREAM)>

	int	rl_getc(FILE *STREAM)

=item C<stuff_char(C)>

	int	rl_stuff_char(int c)

=item C<execute_next(C)>

	int	rl_execute_next(int c)

=item C<clear_pending_input()>

	int	rl_clear_pending_input()			# GRL 4.2

=item C<set_keyboard_input_timeout(uSEC)>

	int	rl_set_keyboard_input_timeout(int usec)		# GRL 4.2

=back

=head4 Terminal Management

=over 4

=item C<prep_terminal(META_FLAG)>

	void	rl_prep_terminal(int META_FLAG)

=item C<deprep_terminal()>

	void	rl_deprep_terminal()

=item C<tty_set_default_bindings([MAP])>

	void	rl_tty_set_default_bindings([Keymap|str map = rl_get_keymap()])	# GRL 4.0

=item C<tty_unset_default_bindings([MAP])>

	void	rl_tty_unset_default_bindings([Keymap|str map = rl_get_keymap()]) # GRL 5.0

=item C<tty_set_echoing(VALUE)>

	int	rl_tty_set_echoing(int value)			# GRL 7.0

=item C<reset_terminal([TERMINAL_NAME])>

	int	rl_reset_terminal(str terminal_name = getenv($TERM))

=back

=head4 Utility Functions

=over 4

=item C<save_state(READLINE_STATE)>

	READLINE_STATE	rl_save_state()				# GRL 6.0

=item C<restore_state(READLINE_STATE)>

	int	rl_restore_state(READLINE_STATE)		# GRL 6.0

=item C<free(MEM)>

	Not implemented since not required for Perl.
	int	rl_free(void *mem)				# GRL 6.0

=item C<replace_line(TEXT [,CLEAR_UNDO])>

	int	rl_replace_line(str text, int clear_undo = 0)	# GRL 4.3

=item C<extend_line_buffer(LEN)>

	Not implemented since not required for Perl.
	int	rl_extend_line_buffer(int len)

=item C<initialize>

	int	rl_initialize()

=item C<ding>

	int	rl_ding()

=item C<alphabetic(C)>

	int	rl_alphabetic(int C)				# GRL 4.2

=item C<display_match_list(MATCHES [,LEN [,MAX]])>

	void	rl_display_match_list(\@matches, len = $#maches, max) # GRL 4.0

Since the first element of an array C<@matches> as treated as a possible
completion, it is not displayed.  See the descriptions of
C<completion_matches()>.
When C<MAX> is omitted, the max length of an item in C<@matches> is used.

=back

=head4 Miscellaneous Functions

=over 4

=item C<macro_bind(KEYSEQ, MACRO [,MAP])>

	int	rl_macro_bind(const str keyseq, const str macro, Keymap map)

=item C<macro_dumper(READABLE)>

	int	rl_macro_dumper(int readline)

=item C<variable_bind(VARIABLE, VALUE)>

	int	rl_variable_bind(const str variable, const str value)

=item C<variable_value(VARIABLE)>

	str	rl_variable_value(const str variable)		# GRL 5.1

=item C<variable_dumper(READABLE)>

	int	rl_variable_dumper(int readline)

=item C<set_paren_blink_timeout(uSEC)>

	int	rl_set_paren_blink_timeout(usec)		# GRL 4.2

=item C<get_termcap(cap)>

	str	rl_get_termcap(cap)

=item C<clear_history>

    void	rl_clear_history()				# GRL 6.3

=back

=head4 Alternate Interface

=over 4

=item C<callback_handler_install(PROMPT, LHANDLER)>

	void	rl_callback_handler_install(str prompt, pfunc lhandler)

=item C<callback_read_char>

	void	rl_callback_read_char()

=item C<callback_sigcleanup>					# GRL 7.0

	void	rl_callback_sigcleanup()

=item C<callback_handler_remove>

	void	rl_callback_handler_remove()

=back

=head3 Readline Signal Handling

=over 4

=item C<pending_signal()>

	int	rl_pending_signal()				# GRL 7.0

=item C<cleanup_after_signal>

	void	rl_cleanup_after_signal()			# GRL 4.0

=item C<free_line_state>

	void	rl_free_line_state()				# GRL 4.0

=item C<reset_after_signal>

	void	rl_reset_after_signal()				# GRL 4.0

=item C<echo_signal_char>

	void	rl_echo_signal_char(int sig)			# GRL 6.0

=item C<resize_terminal>

	void	rl_resize_terminal()				# GRL 4.0

=item C<set_screen_size(ROWS, COLS)>

	void	rl_set_screen_size(int ROWS, int COLS)		# GRL 4.2

=item C<get_screen_size()>

	(int rows, int cols)	rl_get_screen_size()		# GRL 4.2

=item C<reset_screen_size()>

	void	rl_reset_screen_size()				# GRL 5.1

=item C<set_signals>

	int	rl_set_signals()				# GRL 4.0

=item C<clear_signals>

	int	rl_clear_signals()				# GRL 4.0

=back

=head3 Completion Functions

=over 4

=item C<complete_internal([WHAT_TO_DO])>

	int	rl_complete_internal(int what_to_do = TAB)

=item C<completion_mode(FUNCTION)>

	int	rl_completion_mode(FunctionPtr|str function)	# GRL 4.3

=item C<completion_matches(TEXT [,FUNC])>

	(@str)	rl_completion_matches(str text,
				      pfunc func = filename_completion_function)

=item C<filename_completion_function(TEXT, STATE)>

	str	rl_filename_completion_function(str text, int state)

=item C<username_completion_function(TEXT, STATE)>

	str	rl_username_completion_function(str text, int state)

=item C<list_completion_function(TEXT, STATE)>

	str	list_completion_function(str text, int state)	# TRG original

=back

=head3 History Functions

=head4 Initializing History and State Management

=over 4

=item C<using_history>

	void	using_history()

=item C<history_get_history_state>

	HISTORY_STATE	history_get_hitory_state()		# GRL 6.3

=item C<history_set_history_state>

	void	history_set_hitory_state(HISTORY_STATE)		# GRL 6.3

=back

=head4 History List Management

=over 4

=item C<add_history(STRING)>

	void	add_history(str string)

=item C<add_history_time(STRING)>

	void	add_history_time(str string)			# GRL 5.0

=item C<remove_history(WHICH)>

	str	remove_history(int which)

=item C<free_history(HISTENT)>

	Not implemented since Term::ReadLine::Gnu does not support the
	member 'data' of HIST_ENTRY structure. remove_history() frees
	the memory.
	histdata_t	free_history_entry(HIST_ENTRY *histent)	# GRL 5.0

=item C<replace_history_entry(WHICH, STRING)>

	str	replace_history_entry(int which, str string)

=item C<clear_history>

	void	clear_history()

=item C<StifleHistory(MAX)>

	int	stifle_history(int max|undef)

stifles the history list, remembering only the last C<MAX> entries.
If C<MAX> is undef, remembers all entries.  This is a replacement
of C<unstifle_history()>.

=item C<unstifle_history>

	int	unstifle_history()

This is equivalent with C<stifle_history(undef)>.

=item C<history_is_stifled>

	int	history_is_stifled()

=item C<SetHistory(LINE1 [, LINE2, ...])>

sets the history of input, from where it can be used if the actual
C<readline> is present.

=back

=head4 Information About the History List

=over 4

=item C<history_list>

	Not implemented since not required for Perl.
	HIST_ENTRY **history_list()

=item C<where_history>

	int	where_history()

=item C<current_history>

	str	current_history()

=item C<history_get(OFFSET)>

	str	history_get(offset)

=item C<history_get_time(OFFSET)>

	time_t	history_get_time(offset)			# GRL 5.0

=item C<history_total_bytes>

	int	history_total_bytes()

=item C<GetHistory>

returns the history of input as a list, if actual C<readline> is present.

=back

=head4 Moving Around the History List

=over 4

=item C<history_set_pos(POS)>

	int	history_set_pos(int pos)

=item C<previous_history>

	str	previous_history()

=item C<next_history>

	str	next_history()

=back

=head4 Searching the History List

=over 4

=item C<history_search(STRING [,DIRECTION])>

	int	history_search(str string, int direction = -1)

=item C<history_search_prefix(STRING [,DIRECTION])>

	int	history_search_prefix(str string, int direction = -1)

=item C<history_search_pos(STRING [,DIRECTION [,POS]])>

	int	history_search_pos(str string,
				   int direction = -1,
				   int pos = where_history())

=back

=head4 Managing the History File

=over 4

=item C<ReadHistory([FILENAME [,FROM [,TO]]])>

	int	read_history(str filename = '~/.history',
			     int from = 0, int to = -1)

	int	read_history_range(str filename = '~/.history',
				   int from = 0, int to = -1)

adds the contents of C<FILENAME> to the history list, a line at a
time.  If C<FILENAME> is false, then read from F<~/.history>.  Start
reading at line C<FROM> and end at C<TO>.  If C<FROM> is omitted or
zero, start at the beginning.  If C<TO> is omitted or less than
C<FROM>, then read until the end of the file.  Returns true if
successful, or false if not.  C<read_history()> is an alias of
C<read_history_range()>.

=item C<WriteHistory([FILENAME])>

	int	write_history(str filename = '~/.history')

writes the current history to C<FILENAME>, overwriting C<FILENAME> if
necessary.  If C<FILENAME> is false, then write the history list to
F<~/.history>.  Returns true if successful, or false if not.


=item C<append_history(NELEMENTS [,FILENAME])>

	int	append_history(int nelements, str filename = '~/.history')

=item C<history_truncate_file([FILENAME [,NLINES]])>

	int	history_truncate_file(str filename = '~/.history',
				      int nlines = 0)

=back

=head4 History Expansion

=over 4

=item C<history_expand(STRING)>

	(int result, str expansion) history_expand(str string)

Note that this function returns C<expansion> in the scalar context.

=item C<get_history_event(STRING, CINDEX [,QCHAR])>

	(str text, int cindex) = get_history_event(str  string,
						   int  cindex,
						   char qchar = '\0')

=item C<history_tokenize(STRING)>

	(@str)	history_tokenize(str string)

=item C<history_arg_extract(STRING, [FIRST [,LAST]])>

	str history_arg_extract(str string, int first = 0, int last = '$')

=back

=head2 C<Term::ReadLine::Gnu> Variables

Following GNU Readline/History Library variables can be accessed by a
Perl program.  See L<GNU Readline Library
Manual|http://cnswww.cns.cwru.edu/php/chet/readline/readline.html> and
L<GNU History Library
Manual|http://cnswww.cns.cwru.edu/php/chet/readline/history.html> for
details of each variable.  You can access them by using C<Attribs>
methods.  Names of keys in this hash conform to standard conventions
with the leading C<rl_> stripped.

Examples:

    $attribs = $term->Attribs;
    $v = $attribs->{library_version};	# rl_library_version
    $v = $attribs->{history_base};	# history_base

=head3 Readline Variables

	str rl_line_buffer
	int rl_point
	int rl_end
	int rl_mark
	int rl_done
	int rl_num_chars_to_read (GRL 4.1)
	int rl_pending_input
	int rl_dispatching
	int rl_erase_empty_line (GRL 4.0)
	str rl_prompt (read only)
	str rl_display_prompt
	int rl_already_prompted (GRL 4.1)
	str rl_library_version (read only)
	int rl_readline_version (read only)
	int rl_gnu_readline_p (GRL 4.1, read only)
	str rl_terminal_name
	str rl_readline_name
	filehandle rl_instream
	filehandle rl_outstream
	int rl_prefer_env_winsize (GRL 5.1)
	pfunc rl_last_func (GRL 4.2, read only)
	pfunc rl_startup_hook
	pfunc rl_pre_input_hook (GRL 4.0)
	pfunc rl_event_hook
	pfunc rl_getc_function
	pfunc rl_signal_event_hook (GRL 6.3)
	pfunc rl_input_available_hook (GRL 6.3)
	pfunc rl_redisplay_function
	pfunc rl_prep_term_function (GRL 2.1)
	pfunc rl_deprep_term_function (GRL 2.1)
	Keymap rl_executing_keymap (read only)
	Keymap rl_binding_keymap (read only)
	str rl_executing_macro (GRL 4.2, read only)
	int rl_executing_key (GRL 6.3, read only)
	str rl_executing_keyseq (GRL 6.3, read only)
	int rl_key_sequence_length (read only)
	int rl_readline_state (GRL 4.2)
	int rl_explicit_arg (read only)
	int rl_numeric_arg (read only)
	int rl_editing_mode (read only)

=head3 Signal Handling Variables

	int rl_catch_signals (GRL 4.0)
	int rl_catch_sigwinch (GRL 4.0)
	int rl_persistent_signal_handlers (GRL 7.0)
	int rl_change_environment (GRL 6.3)

=head3 Completion Variables

	pfunc rl_completion_entry_function
	pfunc rl_attempted_completion_function
	pfunc rl_filename_quoting_function
	pfunc rl_filename_dequoting_function
	pfunc rl_char_is_quoted_p
	pfunc rl_ignore_some_completions_function
	pfunc rl_directory_completion_hook
	pfunc rl_directory_rewrite_hook (GRL 4.2)
	pfunc rl_filename_stat_hook (GRL 6.3)
	pfunc rl_filename_rewrite_hook (GRL 6.1)
	pfunc rl_completion_display_matches_hook (GRL 4.0)
	str rl_basic_word_break_characters
	str rl_basic_quote_characters
	str rl_completer_word_break_characters
	pfunc rl_completion_word_break_hook (GRL 5.0)
	str rl_completer_quote_characters
	str rl_filename_quote_characters
	str rl_special_prefixes
	int rl_completion_query_items
	int rl_completion_append_character
	int rl_completion_suppress_append (GRL 4.3)
	int rl_completion_quote_character (GRL 5.0, read only)
	int rl_completion_suppress_quote (GRL 5.0)
	int rl_completion_found_quote (GRL 5.0, read only)
	int rl_completion_mark_symlink_dirs (GRL 4.3)
	int rl_ignore_completion_duplicates
	int rl_filename_completion_desired
	int rl_filename_quoting_desired
	int rl_attempted_completion_over
	int rl_sort_completion_matches (GRL 6.0)
	int rl_completion_type (read only)
	int rl_completion_invoking_key (GRL 6.0, read only)
	int rl_inhibit_completion

=head3 History Variables

	int history_base
	int history_length
	int history_max_entries (called `max_input_history', read only)
	int history_write_timestamps (GRL 5.0)
	char history_expansion_char
	char history_subst_char
	char history_comment_char
	str history_word_delimiters (GRL 4.2)
	str history_search_delimiter_chars
	str history_no_expand_chars
	int history_quotes_inhibit_expansion
	pfunc history_inhibit_expansion_function

=head3 Function References

	rl_getc
	rl_redisplay
	rl_callback_read_char
	rl_display_match_list
	rl_filename_completion_function
	rl_username_completion_function
	list_completion_function
	shadow_redisplay
	Tk_getc

=head2 Custom Completion

In this section variables and functions for custom completion are
described along with examples.

Most of descriptions in this section came from L<GNU Readline
Library
Manual|http://cnswww.cns.cwru.edu/php/chet/readline/readline.html>.

=over 4

=item C<completion_entry_function>

This variable holds reference refers to a generator function for
C<completion_matches()>.

A generator function is called repeatedly from
C<completion_matches()>, returning a string each time.  The arguments
to the generator function are C<TEXT> and C<STATE>.  C<TEXT> is the
partial word to be completed.  C<STATE> is zero the first time the
function is called, allowing the generator to perform any necessary
initialization, and a positive non-zero integer for each subsequent
call.  When the generator function returns C<undef> this signals
C<completion_matches()> that there are no more possibilities left.

If this variable set to undef, built-in C<filename_completion_function> is
used.

A sample generator function, C<list_completion_function>, is defined
in Gnu.pm.  You can use it as follows;

    use Term::ReadLine;
    ...
    my $term = new Term::ReadLine 'sample';
    my $attribs = $term->Attribs;
    ...
    $attribs->{completion_entry_function} =
	$attribs->{list_completion_function};
    ...
    $attribs->{completion_word} =
	[qw(reference to a list of words which you want to use for completion)];
    $term->readline("custom completion>");

See also C<completion_matches>.

=item C<attempted_completion_function>

A reference to an alternative function to create matches.

The function is called with C<TEXT>, C<LINE_BUFFER>, C<START>, and
C<END>.  C<LINE_BUFFER> is a current input buffer string.  C<START>
and C<END> are indices in C<LINE_BUFFER> saying what the boundaries of
C<TEXT> are.

If this function exists and returns null list or C<undef>, or if this
variable is set to C<undef>, then an internal function
C<rl_complete()> will call the value of
C<completion_entry_function> to generate matches, otherwise the
array of strings returned will be used.

The default value of this variable is C<undef>.  You can use it as follows;

    use Term::ReadLine;
    ...
    my $term = new Term::ReadLine 'sample';
    my $attribs = $term->Attribs;
    ...
    sub sample_completion {
        my ($text, $line, $start, $end) = @_;
        # If first word then username completion, else filename completion
        if (substr($line, 0, $start) =~ /^\s*$/) {
    	    return $term->completion_matches($text,
					     $attribs->{'username_completion_function'});
        } else {
    	    return ();
        }
    }
    ...
    $attribs->{attempted_completion_function} = \&sample_completion;

=item C<completion_matches(TEXT, ENTRY_FUNC)>

Returns an array of strings which is a list of completions for
C<TEXT>.  If there are no completions, returns C<undef>.  The first
entry in the returned array is the substitution for C<TEXT>.  The
remaining entries are the possible completions.

C<ENTRY_FUNC> is a generator function which has two arguments, and
returns a string.  The first argument is C<TEXT>.  The second is a
state argument; it is zero on the first call, and non-zero on
subsequent calls.  C<ENTRY_FUNC> returns C<undef> to the caller when
there are no more matches.

If the value of C<ENTRY_FUNC> is undef, built-in
C<filename_completion_function> is used.

C<completion_matches> is a Perl wrapper function of an internal
function C<completion_matches()>.  See also
C<completion_entry_function>.

=item C<completion_function>

A variable whose content is a reference to a function which returns a
list of candidates to complete.

This variable is compatible with L<Term::ReadLine::Perl|http://search.cpan.org/dist/Term-ReadLine-Perl/> and very easy
to use.

    use Term::ReadLine;
    ...
    my $term = new Term::ReadLine 'sample';
    my $attribs = $term->Attribs;
    ...
    $attribs->{completion_function} = sub {
	my ($text, $line, $start) = @_;
	return qw(a list of candidates to complete);
    };

=item C<list_completion_function(TEXT, STATE)>

A sample generator function defined by C<Term::ReadLine::Gnu>.
Example code at C<completion_entry_function> shows how to use this
function.

=back

=head2 C<Term::ReadLine::Gnu> Specific Features

=head3 C<Term::ReadLine::Gnu> Specific Functions

=over 4

=item C<CallbackHandlerInstall(PROMPT, LHANDLER)>

This method provides the function C<rl_callback_handler_install()>
with the following additional feature compatible with C<readline>
method; ornament feature, L<Term::ReadLine::Perl|http://search.cpan.org/dist/Term-ReadLine-Perl/> compatible
completion function, history expansion, and addition to history
buffer.

=item C<call_function(FUNCTION, [COUNT [,KEY]])>

	int	rl_call_function(FunctionPtr|str function, count = 1, key = -1)

=item C<get_all_function_names>

Returns a list of all function names.

=item C<shadow_redisplay>

A redisplay function for password input.  You can use it as follows;

	$attribs->{redisplay_function} = $attribs->{shadow_redisplay};
	$line = $term->readline("password> ");

=item C<filename_list>

Returns candidates of filenames to complete.  This function can be used
with C<completion_function> and is implemented for the compatibility
with L<Term::ReadLine::Perl|http://search.cpan.org/dist/Term-ReadLine-Perl/>.

=item C<list_completion_function>

See the description of section L<"Custom Completion"|"Custom Completion">.

=back

=head3 C<Term::ReadLine::Gnu> Specific Variables

=over 4

=item C<do_expand>

When true, the history expansion is enabled.  By default false.

=item C<completion_function>

See the description of section L<"Custom Completion"|"Custom Completion">.

=item C<completion_word>

A reference to a list of candidates to complete for
C<list_completion_function>.

=back

=head3 C<Term::ReadLine::Gnu> Specific Commands

=over 4

=item C<history-expand-line>

The equivalent of the Bash C<history-expand-line> editing command.

=item C<operate-and-get-next>

The equivalent of the Korn shell C<operate-and-get-next-history-line>
editing command and the Bash C<operate-and-get-next>.

This command is bound to C<\C-o> by default for the compatibility with
the Bash and L<Term::ReadLine::Perl|http://search.cpan.org/dist/Term-ReadLine-Perl/>.

=item C<display-readline-version>

Shows the version of C<Term::ReadLine::Gnu> and the one of the GNU
Readline Library.

=item C<change-ornaments>

Change ornaments interactively.

=back

=head1 FILES

=over 4

=item F<~/.inputrc>

Readline init file.  Using this file it is possible that you would
like to use a different set of key bindings.  When a program which
uses the GNU Readline library starts up, the init file is read, and
the key bindings are set.

The conditional init constructs is supported.  The program name which is
specified by the first argument of C<new> method is used as the
application construct.

For example, when your program calls C<new> method as follows;

	...
	$term = new Term::ReadLine 'PerlSh';
	...

your F<~/.inputrc> can define key bindings only for the program as
follows;

	...
	$if PerlSh
	Meta-Rubout: backward-kill-word
	"\C-x\C-r": re-read-init-file
        "\e[11~": "Function Key 1"
	$endif
	...

For further details, see the section "Readline Init File" in the L<GNU
Readline Library
Manual|http://cnswww.cns.cwru.edu/php/chet/readline/readline.html>

=back

=head1 EXPORTS

No symbols are exported by default.
The following tags are defined and their symbols can be exported.

=over 4

=item prompt

RL_PROMPT_START_IGNORE RL_PROMPT_END_IGNORE

=item match_type

NO_MATCH SINGLE_MATCH MULT_MATCH

=item keymap_type

ISFUNC ISKMAP ISMACR

=item undo_code

UNDO_DELETE UNDO_INSERT UNDO_BEGIN UNDO_END

=item rl_state

RL_STATE_NONE RL_STATE_INITIALIZING
RL_STATE_INITIALIZED RL_STATE_TERMPREPPED
RL_STATE_READCMD RL_STATE_METANEXT
RL_STATE_DISPATCHING RL_STATE_MOREINPUT
RL_STATE_ISEARCH RL_STATE_NSEARCH
RL_STATE_SEARCH RL_STATE_NUMERICARG
RL_STATE_MACROINPUT RL_STATE_MACRODEF
RL_STATE_OVERWRITE RL_STATE_COMPLETING
RL_STATE_SIGHANDLER RL_STATE_UNDOING
RL_STATE_INPUTPENDING RL_STATE_TTYCSAVED
RL_STATE_CALLBACK RL_STATE_VIMOTION
RL_STATE_MULTIKEY RL_STATE_VICMDONCE
RL_STATE_CHARSEARCH RL_STATE_REDISPLAYING
RL_STATE_DONE

=back

They can be exported as follows;

	use Term::ReadLine;
	BEGIN {
	    import Term::ReadLine::Gnu qw(:keymap_type RL_STATE_INITIALIZED);
	}

=head1 ENVIRONMENT

The environment variable C<PERL_RL> governs which ReadLine clone is
loaded.  See the ENVIRONMENT section on
L<Term::ReadLine|http://search.cpan.org/dist/Term-ReadLine/> for
further details.

=head1 SEE ALSO

=over 4

=item L<Term::ReadLine::Gnu Project Home Page|http://sourceforge.net/projects/perl-trg/>

=item L<GNU Readline Library Manual|http://cnswww.cns.cwru.edu/php/chet/readline/readline.html>

=item L<GNU History Library Manual|http://cnswww.cns.cwru.edu/php/chet/readline/history.html>

=item Sample and test programs (F<eg/*> and F<t/*>) in L<the C<Term::ReadLine::Gnu> distribution|http://search.cpan.org/dist/Term-ReadLine-Gnu/>

=item L<Term::ReadLine|http://search.cpan.org/dist/Term-ReadLine/>

=item Works which use Term::ReadLine::Gnu

=over 4

=item Distributions which depend on Term::ReadLine::Gnu on L<CPAN|http://www.cpan.org/>

L<https://metacpan.org/requires/distribution/Term-ReadLine-Gnu>

=item L<Perl Debugger|http://perldoc.perl.org/perldebug.html>

	perl -d

=item L<Perl Shell (psh)|http://gnp.github.io/psh/>

The Perl Shell is a shell that combines the interactive nature of a
Unix shell with the power of Perl.

A programmable completion feature compatible with bash is implemented.

=item L<SPP (Synopsys Plus Perl)|http://vlsiweb.stanford.edu/~jsolomon/SPP/>

SPP (Synopsys Plus Perl) is a Perl module that wraps around Synopsys'
shell programs.  SPP is inspired by the original dc_perl written by
Steve Golson, but it's an entirely new implementation.  Why is it
called SPP and not dc_perl?  Well, SPP was written to wrap around any
of Synopsys' shells.

=item L<PFM (Personal File Manager for UnixE<sol>Linux)|http://p-f-m.sourceforge.net/>

Pfm is a terminal-based file manager written in Perl, based on PFM.COM
for MS-DOS (originally by Paul Culley and Henk de Heer).

=item L<The soundgrab|http://brittonkerin.com/soundgrab/soundgrab.html>

soundgrab is designed to help you slice up a big long raw audio file
(by default 44.1 kHz 2 channel signed sixteen bit little endian) and
save your favorite sections to other files. It does this by providing
you with a cassette player like command line interface.

=item L<PDL (The Perl Data Language)|http://pdl.perl.org/>

PDL (``Perl Data Language'') gives standard Perl the ability to
compactly store and speedily manipulate the large N-dimensional data
arrays which are the bread and butter of scientific computing.

=item L<PIQT (Perl Interactive DBI Query Tool)|http://piqt.sourceforge.net/>

PIQT is an interactive query tool using the Perl DBI database
interface. It supports ReadLine, provides a built in scripting language
with a Lisp like syntax, an online help system, and uses wrappers to
interface to the DBD modules.

=item L<vshnu (the New Visual Shell)|http://www.cs.indiana.edu/~kinzler/vshnu/>

A visual shell and CLI shell supplement.

=back

If you know any other works you recommend, please let me know.

=back

=head1 AUTHOR

Hiroo Hayashi C<E<lt>hiroo.hayashi@computer.orgE<gt>>

L<http://search.cpan.org/~hayashi/>

=head1 TODO

GTK+ support in addition to Tk.

=head1 BUGS

=over 4

=item Submit a bug report to
L<rt.cpan.org|https://rt.cpan.org/Dist/Display.html?Name=Term-ReadLine-Gnu>.

=item C<add_defun()> can define up to 16 functions.

=item Some functions and variables do not have test code yet.  Your
contribution is welcome.  See F<t/readline.t> for details.

=item If the pager command (| or ||) in Perl debugger causes segmentation
fault, you need to fix F<perl5db.pl>.  See
L<https://rt.perl.org/Public/Bug/Display.html?id=121456> for details.

=back

=head1 LICENSE

Copyright (c) 1996-2016 Hiroo Hayashi.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
