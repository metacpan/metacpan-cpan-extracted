#=============================================================================
#
#       Module:  Term::CLI::ReadLine
#
#  Description:  Class for Term::CLI and Term::ReadLine glue
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  23/Jan/2018
#
#   Copyright (c) 2018-2022 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

package Term::CLI::ReadLine 0.057001;

use 5.014;
use warnings;

use parent 0.225 qw( Term::ReadLine );

use Term::ReadKey 2.32 ();

use namespace::clean 0.25;

my $DFL_HIST_SIZE = 500;
my $HIST_LIMIT    = 2**64 - 1;
my $Term          = undef;

# Since we cannot be sure what type the Term::ReadLine object
# is (HASH or ARRAY), we'll have to keep some state here.

my $History_Size = $DFL_HIST_SIZE;
my @History      = ();

# Keep a filehandle for Term::ReadKey operations.
my $Term_FH = undef;

# Original_KB_Signals is fetched at `new` time and used to both restore
# the ControlChars as well as validate given key names: not all
# platforms support the same keys.
my %Original_KB_Signals       = ();
my @Default_Ignore_KB_Signals = qw( QUIT );
my %Ignore_KB_Signals         = ();
my %Sig2KeyName               = (
    'INT'  => 'INTERRUPT',
    'QUIT' => 'QUIT',
    'TSTP' => 'SUSPEND',
);

sub new {
    my ( $class, @args ) = @_;

    return $Term if $Term;

    $Term = bless Term::ReadLine->new(@args), $class;

    ## no critic (ProhibitInteractiveTest)
    $Term_FH = -t $Term->OUT ? $Term->OUT : undef;

    %Original_KB_Signals = Term::ReadKey::GetControlChars($Term_FH)
        if $Term_FH;

    if ( eval { exists $Term->Attribs->{catch_signals} } ) {
        $Term->Attribs->{catch_signals} = 1;
    }

    $Term->reset_ignore_keyboard_signals();

    return $Term->_install_stubs;
}

sub term { return $Term }

# Dumb wrapper around "Attrib" that allows mocking the
# `completion_quote_character` state.
sub completion_quote_character {
    my ($self) = @_;
    my $c = $self->term->Attribs->{completion_quote_character} // q{};
    return $c =~ s/\000//rgx;
}

sub ignore_keyboard_signals {
    my ( $self, @args ) = @_;
    foreach my $signame (@args) {
        my $charname = $Sig2KeyName{$signame} or next;
        $Original_KB_Signals{$charname}       or next;
        $Ignore_KB_Signals{$charname} = q{};
    }
    return;
}

sub no_ignore_keyboard_signals {
    my ( $self, @args ) = @_;
    foreach my $signame (@args) {
        my $charname = $Sig2KeyName{$signame} or next;
        $Original_KB_Signals{$charname}       or next;
        delete $Ignore_KB_Signals{$charname};
    }
    return;
}

sub _set_ignore_keyboard_signals {
    my ($self) = @_;
    return if !$Term_FH;
    Term::ReadKey::SetControlChars( %Ignore_KB_Signals, $Term_FH );
    return;
}

sub _restore_keyboard_signals {
    my ($self) = @_;
    return if !$Term_FH;
    Term::ReadKey::SetControlChars( %Original_KB_Signals, $Term_FH );
    return;
}

sub reset_ignore_keyboard_signals {
    my ($self) = @_;
    %Ignore_KB_Signals = ();
    $self->ignore_keyboard_signals(@Default_Ignore_KB_Signals);
    return;
}

sub term_width {
    my ($self) = @_;
    my ( $rows, $cols ) = $self->get_screen_size();
    return $cols;
}

sub term_height {
    my ($self) = @_;
    my ( $rows, $cols ) = $self->get_screen_size();
    return $rows;
}

sub echo_signal_char {
    my ( $self, $sig_arg ) = @_;

    state $name2int = {
        'INT'  => 2,
        'QUIT' => 3,
        'TSTP' => 20
    };

    if ( $self->ReadLine =~ /::Gnu$/x ) {
        if ( $sig_arg =~ /\D/x ) {
            $sig_arg = $name2int->{ uc $sig_arg } or return;
        }
        return $self->SUPER::echo_signal_char($sig_arg);
    }

    state $int2name = { reverse %{$name2int} };

    if ( $sig_arg =~ /^\d+$/x ) {
        $sig_arg = $int2name->{$sig_arg} or return;
    }
    $sig_arg = $Sig2KeyName{$sig_arg} // $sig_arg;
    my $char = $Original_KB_Signals{$sig_arg} or return;
    $char =~ s{ ([\000-\037]) }{'^'.chr(ord($1)+ord('@'))}gex;
    $self->OUT->print($char);

    return;
}

sub _escape_str {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $self, $str ) = @_;
    $str =~ s/\t/\\t/gx;
    $str =~ s/\n/\\n/gx;
    $str =~ s/\r/\\r/gx;
    $str =~ s/([\177-\377])/sprintf("\\%03o", ord($1))/gex;
    $str =~ s/([\000-\037])/'^'.chr(ord($1)+ord('@'))/gex;
    return $str;
}

# The GNU readline implementation will just slap the prompt between the
# ornament-start/ornament-end sequences, but this looks ugly if there
# are leading/trailing spaces and the ornament is set to underline
# (or standout). The following will bring it in line with how the Perl
# implementation handles it, by inserting start/end sequences where
# necessary.
sub _prepare_prompt {
    my ( $self, $prompt ) = @_;

    return $prompt if $self->ReadLine !~ /::Gnu$/x;
    return $prompt if length $self->Attribs->{term_set}[0] == 0;

    my ( $head, $body, $tail ) = $prompt =~ /^(\s*)(.*?)(\s*)$/x;
    return $prompt if ( $head eq q{} and $tail eq q{} );

    #say "prompt:       ", $self->_escape_str("<$head><$body><$tail>");
    #say "start_ignore: ", $self->_escape_str($self->RL_PROMPT_START_IGNORE);
    #say "end_ignore:   ", $self->_escape_str($self->RL_PROMPT_END_IGNORE);
    #say "term_set 0:   ", $self->_escape_str($self->Attribs->{term_set}[0]);
    #say "term_set 1:   ", $self->_escape_str($self->Attribs->{term_set}[1]);

    $prompt = q{};
    if ( length $head ) {
        $prompt
            .= $self->Attribs->{term_set}[1]
            . $head
            . $self->Attribs->{term_set}[0];
    }

    #say $self->_escape_str($prompt);

    $prompt .= $body;

    #say $self->_escape_str($prompt);

    if ( length $tail ) {
        $prompt .= $self->Attribs->{term_set}[1] . $tail;
    }

    #say $self->_escape_str($prompt);

    return $prompt;
}

sub readline {    ## no critic (ProhibitBuiltinHomonyms)
    my ( $self, $prompt ) = @_;

    # local(%SIG) logic does not work... :-(
    my %old_SIG = $self->_set_signal_handlers;

    $prompt = $self->_prepare_prompt($prompt);
    $self->_set_ignore_keyboard_signals();
    my $input = $self->SUPER::readline($prompt);
    $self->_restore_keyboard_signals();

    if ( !$self->Features->{autohistory} ) {
        if ( defined $input && length($input) ) {
            $self->AddHistory($input);
        }
    }
    $self->_restore_signal_handlers( %old_SIG );
    return $input;
}

# CLI->_restore_signal_handlers( $HASH_REF );
#
# Re-set signal handlers that we overrode earlier.
#
sub _restore_signal_handlers {
    my ($self, %old_SIG) = @_;
    # Cannot assign slices to %SIG... :-(
    while ( my ($sig, $handler) = each %old_SIG ) {
        $SIG{$sig} = $handler;
    }
}

# %old_sig = CLI->_set_signal_handlers();
#
# Set signal handlers to ensure proper terminal/CLI handling in the
# face of various signals (^C ^\ ^Z).
#
# Return a hash with the overridden signal handlers.
#
sub _set_signal_handlers {
    ## no critic (RequireLocalizedPunctuationVars)
    my ($self) = @_;

    my %old_SIG;

    @old_SIG{qw( HUP INT QUIT ALRM TERM CONT )}
        = @SIG{qw( HUP INT QUIT ALRM TERM CONT )};

    my $most_recent_signal = q{};

    # The generic signal handler will attempt to re-throw the signal, after
    # putting the terminal in the correct state. Any previously set signal
    # handlers should then be triggered.
    my $generic_handler = sub {
        my ($signal) = @_;

        my $this_handler = $SIG{$signal};
        my $handler      = $old_SIG{$signal} // q{};

        $self->deprep_terminal();
        $self->_restore_keyboard_signals();

        if ( $handler eq q{} or $handler eq 'DEFAULT' ) {

            # We've de-prepped the terminal, now reset the signal handler
            # and re-issue the signal. Since we're inside a signal handler
            # the re-thrown signal will be deferred until we return from
            # this. For HUP, QUIT, ALRM, and TERM, this will result in
            # termination of the process, so leave the terminal in a
            # de-prepped state.
            $SIG{$signal} = 'DEFAULT';
            kill $signal, $$;
            return;
        }

        # Call old signal handler and re-prep the terminal.
        if ( ref $handler ) {
            local ( $SIG{$signal} ) = $handler;
            $handler->( $signal, @_ );
        }

        $self->prep_terminal(1);
        $self->_set_ignore_keyboard_signals();
        $self->forced_update_display();
        return;
    };

    if ( $self->ReadLine =~ /::Gnu$/x ) {
        for my $sig (qw( HUP QUIT ALRM TERM )) {
            if ( ref $old_SIG{$sig} ) {
                $SIG{$sig} = $generic_handler;
            }
        }
    }
    else {
        $SIG{HUP} = $SIG{QUIT} = $SIG{ALRM} = $SIG{TERM} = $generic_handler;
    }

    # The INT signal handler; slightly different from
    # the generic one: we abort the current input line.
    $SIG{INT} = sub {
        my ($signal) = @_;
        if ( $self->ReadLine =~ /::Gnu$/x ) {
            $self->crlf;
        }
        $self->replace_line(q{});
        $generic_handler->($signal);
        return 1;
    };

    # The CONT signal handler.
    # In case we get suspended, make sure we redraw the CLI on wake-up.
    $SIG{CONT} = sub {
        my ($signal) = @_;
        $most_recent_signal = $signal;
        $old_SIG{$signal}->(@_) if ref $old_SIG{$signal};
        $self->_set_ignore_keyboard_signals();
        return 1;
    };

    # GNU readline will call the signal_event_hook after handling
    # a signal, so use this to force a display update after a 'CONT'
    # signal.
    $self->Attribs->{signal_event_hook} = sub {
        if ( $most_recent_signal eq 'CONT' ) {
            $self->forced_update_display();
        }
        $most_recent_signal = '';
        return 1;
    };

    return %old_SIG;
}

# Install stubs for common GRL methods.
sub _install_stubs {
    my ($self) = @_;

    return $self if $self->ReadLine =~ /::Gnu$/x;

    no warnings 'once';    ## no critic (ProhibitNoWarnings)

    *{free_line_state} = sub { };
    *{crlf}            = sub { $self->OUT->print("\n") };

    *{get_screen_size} = sub {
        my ( $width, $height ) = Term::ReadKey::GetTerminalSize($Term_FH);
        return ( $height, $width );
    };

    if ( $self->ReadLine !~ /::Perl$/x ) {
        *{replace_line} = *{prep_terminal} = *{deprep_terminal} =
            *{forced_update_display} = sub { };

        return $self;
    }

    *{replace_line}          = \&_perl_replace_line;
    *{prep_terminal}         = \&_perl_prep_terminal;
    *{deprep_terminal}       = \&_perl_deprep_terminal;
    *{forced_update_display} = \&_perl_forced_update_display;

    return $self;
}

# Term::ReadLine::Perl implementations of GRL methods.
sub _perl_prep_terminal         { readline::SetTTY();    return; }
sub _perl_deprep_terminal       { readline::ResetTTY();  return; }
sub _perl_forced_update_display { readline::redisplay(); return; }

sub _perl_replace_line {
    my ( $self, $line ) = @_;
    $line //= q{};
    ## no critic (ProhibitPackageVars)
    $readline::line = $line;
    $readline::D    = length($line) if $readline::D > length($line);
    return;
}

sub ReadHistory {
    my ( $self, $hist_file ) = @_;

    if ( $self->Features->{'readHistory'} ) {
        return $self->SUPER::ReadHistory($hist_file);
    }

    open my $fh, '<', $hist_file or return;

    my @history;
    while (<$fh>) {
        next if $_ eq "\n";
        chomp;
        shift @history if @history == $History_Size;
        push @history, $_;
    }
    $fh->close;

    $self->term->SetHistory(@history);
    return 1;
}

sub WriteHistory {
    my ( $self, $hist_file ) = @_;

    if ( $self->Features->{'writeHistory'} ) {
        return $self->SUPER::WriteHistory($hist_file);
    }

    open my $fh, '>', $hist_file or return;
    print $fh map {"$_\n"} $self->term->GetHistory or return;
    $fh->close                                     or return;
    return 1;
}

*{stifle_history} = \&StifleHistory;

sub StifleHistory {
    my ( $self, $max ) = @_;

    if ( $self->Features->{'stiflehistory'} ) {
        return $self->SUPER::StifleHistory($max);
    }

    $max //= $HIST_LIMIT;
    $max = 0 if $max <= 0;

    if ( $self->ReadLine =~ /::Perl$/x ) {
        ## no critic (ProhibitPackageVars)
        $readline::rl_MaxHistorySize = $max;
        my $cur = int @readline::rl_History;
        if ( $cur > $max ) {
            splice( @readline::rl_History, 0, -$max );
            $readline::rl_HistoryIndex -= ( $cur - $max );
        }
        return $max;
    }

    splice( @History, 0, -$max ) if @History > $max;
    $History_Size = $max;
    return $max;
}

sub GetHistory {
    my ($self) = @_;

    if ( $self->Features->{'getHistory'} ) {
        return $self->SUPER::GetHistory();
    }
    return @History;
}

sub SetHistory {
    my ( $self, @l ) = @_;

    splice( @l, 0, -$History_Size ) if @l > $History_Size;

    if ( $self->Features->{'setHistory'} ) {
        return $self->SUPER::SetHistory(@l);
    }

    @History = @l;

    return int(@History);
}

sub AddHistory {
    my ( $self, @lines ) = @_;

    if ( $self->Features->{'addHistory'} ) {
        return $self->SUPER::AddHistory(@lines);
    }

    push @History, @lines;
    splice( @History, 0, -$History_Size ) if int(@History) > $History_Size;
    return;
}

1;

__END__

=pod

=head1 NAME

Term::CLI::ReadLine - Term::ReadLine compatibility layer for Term::CLI

=head1 VERSION

version 0.057001

=head1 SYNOPSIS

 use Term::CLI::ReadLine;

 sub initialise {
    my $term = Term::CLI::ReadLine->new( ... );
    ... # Use Term::ReadLine methods on $term.
 }

 # The original $term reference is now out of scope, but
 # we can get a reference to it again:

 sub somewhere_else {
    my $term = Term::CLI::ReadLine->term;
    ... # Use Term::ReadLine methods on $term.
 }

=head1 DESCRIPTION

This class provides a compatibility layer between L<Term::ReadLine>(3p)
and L<Term::CLI>(3p). If L<Term::ReadLine::Gnu>(3p) is not loaded as the
C<Term::ReadLine> implementation, this class will compensate for the lack
of certain functions by replacing or wrapping methods that are needed
by the rest of the L<Term::CLI>(3p) classes.

The ultimate purpose is to behave as consistently as possible regardless
of the C<Term::ReadLine> interface that has been loaded.

This class inherits from L<Term::ReadLine> and behaves as a singleton
with a class accessor to access that single instance, because
even though L<Term::ReadLine>(3p) has an object-oriented interface,
the L<Term::ReadLine::Gnu>(3p) and L<Term::ReadLine::Perl>(3p) modules
really only keep a single instance around (if you create multiple
L<Term::ReadLine> objects, all parameters and history are shared).

=head1 CONSTRUCTORS

=over

=item B<new> ( ... )
X<new>

Create a new L<Term::CLI::ReadLine>(3p) object and return a reference to it.

Arguments are identical to L<Term::ReadLine>(3p).

A reference to the newly created object is stored internally and can be
retrieved later with the L<term|/term> class method. Note that repeated calls
to C<new> will reset this internal reference.

=back

=head1 METHODS

See L<Term::ReadLine>(3p), L<Term::ReadLine::Gnu>(3p) and/or
L<Term::ReadLine::Perl> for the inherited methods.

=over

=item B<completion_quote_character>
X<completion_quote_character>

In a L<Term::ReadLine::Gnu|Term::ReadLine::Gnu> environment this returns
the C<rl_completion_quote_character>. This value is set during completion
if the text to be completed has an open quote. Consider the case:

    foo 'bar <TAB>

When the completion function is called, the C<rl_completion_quote_character>
will contain a single quote, C<'>.

For non-GNU ReadLine backends, this function returns an empty string.

=item B<echo_signal_char> ( I<signal> )
X<echo_signal_char>

Print the character that generates a particular signal when entered from
the keyboard (e.g. C<^C> for keyboard interrupt).

This method also accepts a signal name instead of a signal number. It only
works for C<INT> (2), C<QUIT> (3), and C<TSTP> (20) signals as these are
the only ones that can be entered from a keyboard.

If L<Term::ReadLine::Gnu> is loaded, this method wraps around the method of
the same name in C<Term::ReadLine::Gnu> (translating a signal name to a
number first). For other C<Term::ReadLine> implementations, it emulates the
C<Term::ReadLine::Gnu> behaviour.

=item B<readline> ( I<prompt> )
X<readline>

Wrap around the original L<Term::ReadLine's readline|Term::ReadLine/readline>
with custom signal handling, see the
L<CAVEATS section in Term::CLI|Term::CLI/CAVEATS>.

This also calls C<AddHistory> if C<autohistory> is not set in C<Features>.

=item B<term_width>
X<term_width>

Return the width of the terminal in characters, as given by
L<Term::ReadLine>.

=item B<term_height>
X<term_height>

Return the height of the terminal in characters, as given by
L<Term::ReadLine>.

=item B<ignore_keyboard_signals> ( I<SIGNAME>, ... )
X<ignore_keyboard_signals>

Ensure that I<SIGNAME> signals cannot be entered from the
keyboard. I<SIGNAME> should be the name of a signal that
can be entered from the keyboard, i.e. one of:
C<INT>, C<QUIT>, C<TSTP>.

By default, the C<QUIT> keyboard signal is already disabled.

Notes:

=over

=item 1.

This will only disable the keys for the given signals
I<during> a C<readline> operation. Outside of that, they will still
generate signals.

=item 2.

This only disables the keyboard sequences, not the actual signals
themselves (i.e. you can still C<kill -3 PID> from another terminal.

=item 3.

Disabling the C<INT> key will cause I<Ctrl-C> to no longer discard the
input line under L<Term::ReadLine::Gnu>; it I<will> discard it under
L<Term::ReadLine::Perl>! It is therefore recommended to just set
C<$SIG{INT}> to C<IGNORE> instead.

=item 4.

Disabling the C<TSTP> key works under L<Term::ReadLine::Gnu>, but
not under L<Term::ReadLine::Perl>. The latter maps the key in raw
mode and explicitly sends a C<TSTP> signal to itself.

=back

See also L<SIGNAL HANDLING|/SIGNAL HANDLING> below.

=item B<no_ignore_keyboard_signals> ( I<SIGNAME>, ... )
X<no_ignore_keyboard_signals>

(Re-)Enable keyboard generation for I<SIGNAME> signals.
See L<ignore_keyboard_signals|/ignore_keyboard_signals> above for
valid I<SIGNAME> values.

=item B<reset_ignore_keyboard_signals>
X<reset_ignore_keyboard_signals>

Reset all keyboard signal generation to the defaults.

=item B<AddHistory> ( I<line>, ... )
X<AddHistory>

=item B<GetHistory>
X<GetHistory>

=item B<ReadHistory> ( I<file> )
X<ReadHistory>

=item B<SetHistory> ( I<line>, ... )
X<SetHistory>

=item B<StifleHistory> ( I<max_lines> )
X<StifleHistory>

=item B<stifle_history> ( I<max_lines> )
X<stifle_history>

=item B<WriteHistory> ( I<file> )
X<WriteHistory>

Depending on the underlying C<Term::ReadLine> implementation, these will
either call the parent class's method, or implement a proper emulation.

In the case of C<Term::ReadLine::Perl>, this means that C<ReadHistory>
and C<WriteHistory> implement their own file I/O read/write (because
C<Term::ReadLine::Perl> doesn't provide them); furthermore, C<StifleHistory>
uses knowledge of C<Term::ReadLine::Perl>'s internals to manipulate the
history.

In cases where history is not supported at all (e.g. C<Term::ReadLine::Stub>,
the history list is kept in this object and manipulated.

=back

=head1 STUB METHODS

If C<Term::ReadLine> is I<not> using the GNU ReadLine library, this object
provides stubs for a few GNU ReadLine methods:

=over

=item B<free_line_state>
X<free_line_state>

=item B<forced_update_display>
X<forced_update_display>

If L<Term::ReadLine::Perl> is loaded, this will use knowledge of
its internals to force an redraw of the input line.

=item B<crlf>
X<crlf>

Prints a newline to the terminal's output.

=item B<replace_line> ( I<str> )
X<replace_line>

If L<Term::ReadLine::Perl> is loaded, this will use knowledge of
its internals to replace the current input line with I<str>.

=item B<deprep_terminal>
X<deprep_terminal>

=item B<prep_terminal>
X<prep_terminal>

If L<Term::ReadLine::Perl> is loaded, this will use knowledge of
its internals to either restore (deprep) terminal settings to
what they were before calling C<readline>, or to set them to what
C<readline> uses. You will rarely (if ever) need these, since
the ReadLine libraries usually take care if this themselves.

One exception to this is in signal handlers: C<Term::CLI::ReadLine>
calls these methods during its signal handling.

=item B<get_screen_size>
X<get_screen_size>

Use C<Term::ReadKey::GetTerminalSize> to get the appropriate
dimensions and return them as (I<height>, I<width>).

=back

=head1 CLASS METHODS

=over

=item B<term>
X<term>

Return the latest C<Term::CLI::ReadLine> object created.

=back

=head1 SIGNAL HANDLING

The class sets its own signal handlers in the L<readline|/readline>
function where necessary.

The following signals may be caught:
C<ALRM>, C<CONT>, C<HUP>, C<INT>, C<QUIT>, C<TERM>.

The signal handlers will:

=over

=item *

Restore the terminal to a "sane" state, i.e. the state it was in before
C<readline> was called (the C<CONT> signal being an exception to this
rule).

=item *

If any signal handler was set prior to the call to C<readline>, it will
be called and if control returns L<Term::CLI::ReadLine>'s signal handler,
the terminal will be set back to the state that C<readline> expects it to
be in.

=item *

If the signal handler was previously set to C<DEFAULT>, it is restored
as C<DEFAULT> and the signal is re-thrown, so the default actions (abnormal
exit and possible core dump) can take place.

=back

Just how and when these "wrapper" signal handlers are installed depends on
the selected C<Term::ReadLine> implementation. The
L<Gnu|Term::ReadLine::Gnu> backend doesn't require separate handlers
for signals that are set to C<IGNORE> or C<DEFAULT>. The
L<Perl|Term::ReadLine::Perl> backend does require some wrapping.

The C<INT> signal is always wrapped to ensure that the current input
line is discarded and a newline is emitted.

=head2 Keyboard signals

One subtle difference between the
L<Term::ReadLine::Gnu> and L<Term::ReadLine::Perl> is in keyboard-generated
signal handling (interrupt, quit, suspend).

=over

=item *

L<Term::ReadLine::Perl> disables keyboard-generated signals. When it
reads a I<Ctrl-C>, it will send itself an C<INT> signal, when it
sees a I<Ctrl-Z>, it will send a C<TSTP> signal; the "quit" key
I<Ctrl-\> is simply ignored.

=item *

L<Term::ReadLine::Gnu> leaves keyboard-generated signals enabled and
sets signal handlers to catch them.

=back

This subtle difference means that:

=over

=item *

It is impossible to have I<Ctrl-\> generate a C<QUIT> signal under
L<Term::ReadLine::Perl>.

=item *

It is impossible to disable I<Ctrl-Z> through L</ignore_keyboard_signals>
under L<Term::ReadLine::Perl>.

=item *

Disabling I<Ctrl-C> through L</ignore_keyboard_signals> will completely
disable I<Ctrl-C> under L<Term::ReadLine::Gnu> (will not discard the
input line), but not L<Term::ReadLine::Perl>.

=back

For this reason, the module by default ignores the C<QUIT> key sequence.

=head2 Recommendations

To behave as consistently as possible across the C<Term::ReadLine> backends,
the following is best if you don't want keyboard signals to kill or stop
the program:

=over

=item 1.

Set C<$SIG{INT}> to C<IGNORE>.

=item 2.

Set C<$SIG{TSTP}> to C<IGNORE>.

=item 3.

Ignore keyboard signal C<QUIT> (already default).

=back

=head1 SEE ALSO

L<Term::CLI>(3p),
L<Term::ReadLine>(3p),
L<Term::ReadLine::Gnu>(3p),
L<Term::ReadLine::Perl>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>, 2018-2021.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Steven Bakker

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
