#=============================================================================
#
#       Module:  Term::CLI
#
#  Description:  Class for CLI parsing
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  31/01/18
#
#   Copyright (c) 2018 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

use 5.014_001;

package Term::CLI  0.051007 {

use Modern::Perl 1.20140107;
use Text::ParseWords 3.29 qw( parse_line );
use Term::CLI::ReadLine;
use FindBin 1.50;

use Term::CLI::L10N;

# Load all Term::CLI classes so the user doesn't have to.

use Term::CLI::Argument::Bool;
use Term::CLI::Argument::Enum;
use Term::CLI::Argument::Filename;
use Term::CLI::Argument::Number;
use Term::CLI::Argument::Number::Float;
use Term::CLI::Argument::Number::Int;
use Term::CLI::Argument::String;

use Term::CLI::Command;
use Term::CLI::Command::Help;

use Types::Standard 1.000005 qw(
    ArrayRef
    CodeRef
    InstanceOf
    Maybe
    RegexpRef
    Str
    Int
);

use Moo 1.000001;
use namespace::clean 0.25;

extends 'Term::CLI::Base';

with('Term::CLI::Role::CommandSet');

# Provide a default for 'name'.
has '+name' => (
    default => sub { $FindBin::Script }
);

has prompt => (
    is => 'rw',
    isa => Str,
    default => sub { '~> ' }
);

has split_function => (
    is => 'rw',
    isa => CodeRef,
    default => sub { \&_default_split }
);

has skip => (
    is => 'rw',
    isa => RegexpRef,
);

has history_file => (
    is => 'rw',
    isa => Str
);

has history_lines => (
    is => 'rw',
    isa => Int,
    default => sub { 1000 },
    trigger => 1,
);

has word_delimiters  => ( is => 'rw', isa => Str, default => sub {" \n\t"} );
has quote_characters => ( is => 'rw', isa => Str, default => sub {q("')} );

sub BUILD {
    my ($self, $args) = @_;

    my $term = Term::CLI::ReadLine->new($self->name)->term;
    $term->Attribs->{completion_function} = sub { $self->complete_line(@_) };
    $term->Attribs->{char_is_quoted_p} = sub { $self->_is_escaped(@_) };

    $self->_set_completion_attribs;

    if (! exists $args->{callback} ) {
        $self->callback(\&_default_callback);
    }

    if (!exists $args->{history_file}) {
        my $hist_file = $self->name;
        $hist_file =~ s{^/}{}g;
        $hist_file =~ s{/$}{}g;
        $hist_file =~ s{/+}{-}g;
        $self->history_file("$::ENV{HOME}/.${hist_file}_history");
    }

    # Set ReadLine history size...
    $self->term->StifleHistory($self->history_lines);
}

sub _trigger_history_lines {
    my ($self, $arg) = @_;

    # the ReadLine object may not have been initialised yet...
    $self->term->StifleHistory($arg) if $self->term;
}

# %args = $self->_default_callback(%args);
#
# Default top-level callback if none is given.
# Simply check the status and print an error
# message if status < 0.
sub _default_callback {
    my ($self, %args) = @_;

    if ($args{status} < 0) {
        say STDERR loc("ERROR"), ": ", $args{error};
    }
    return %args;
}


# ($error, @words) = $self->_default_split($text);
#
# Default function to split a string into words.
# Similar to "shellwords()", except that we use
# "parse_line" to support custom delimiters.
#
# Unfortunately, there's no way to specify custom
# quote characters.
#
sub _default_split {
    my ($self, $text) = @_;

    if ($text =~ /\S/) {
        my $delim = $self->word_delimiters;
        $text =~ s/^[$delim]+//;
        my @words = parse_line(qr{[$delim]+}, 0, $text);
        pop @words if @words and not defined $words[-1];
        my $error = @words ? '' : loc('unbalanced quotes in input');
        return ($error, @words);
    }
    else {
        return ('');
    }
}


# BOOL = CLI->_is_escaped($line, $index);
#
# The character at $index in $line is a possible word break
# character. Check if it is perhaps escaped.
#
sub _is_escaped {
    my ($self,$line, $index) = @_;
    return 0 if $index <= 0;
    return 0 if substr($line, $index-1, 1) ne '\\';
    return !$self->_is_escaped($line, $index-1);
}


# CLI->_set_completion_attribs();
#
# Set some attributes in the Term::ReadLine object related to
# custom completion.
#
sub _set_completion_attribs {
    my $self = shift;
    my $term = $self->term;

    # Default: '"
    $term->Attribs->{completer_quote_characters} = $self->quote_characters;

    # Default: \n\t\\"'`@$><=;|&{( and <space>
    $term->Attribs->{completer_word_break_characters} = $self->word_delimiters;

    # Default: <space>
    $term->Attribs->{completion_append_character}
        = substr($self->word_delimiters, 0, 1);
}


# CLI->_split_line( $text );
#
# Attempt to split $text into words. Use a custom split function if
# necessary.
#
sub _split_line {
    my ($self, $text) = @_;
    return $self->split_function->($self, $text);
}


# See POD X<complete_line>
sub complete_line {
    my ($self, $text, $line, $start) = @_;

    $self->_set_completion_attribs;

    my $quote_char
        = $self->term->Attribs->{completion_quote_character} =~ s/\000//gr;

    my @words;

    if ($start > 0) {
        if (length $quote_char) {
            # ReadLine thinks the $text to be completed is quoted.
            # The quote character will precede the $start of $text.
            # Make sure we do not include it in the text to break
            # into words...
            (my $err, @words) = $self->_split_line(substr($line, 0, $start-1));
        }
        else {
            (my $err, @words) = $self->_split_line(substr($line, 0, $start));
        }
    }

    push @words, $text;

    my @list;

    if (@words == 1) {
        @list = grep { rindex($_, $words[0], 0) == 0 } $self->command_names;
    }
    elsif (my $cmd = $self->find_command($words[0])) {
        @list = $cmd->complete_line(@words[1..$#words]);
    }

    # Escape spaces in reply if necessary.
    if (length $quote_char) {
        return @list;
    }
    else {
        my $delim = $self->word_delimiters;
        return map { s/([$delim])/\\$1/gr } @list;
    }
}


# %old_sig = CLI->_set_signal_handlers();
#
# Set signal handlers to ensure proper terminal/CLI handling in the
# face of various signals (^C ^\ ^Z).
#
sub _set_signal_handlers {
    my $self = shift;

    my %old_sig = %SIG;

    # $last_signal is set by the signal handlers and is used
    # in the term's "Attrib{signal_event_hook}" to determine
    # what action to take.
    my $last_signal = 'NONE';

    # The generic signal handler will attempt to re-throw the signal, after
    # putting the terminal in the correct state. Any previously set signal
    # handlers should then be triggered.
    my $generic_handler = sub {
        my $signal = shift;

        $last_signal = $signal;

        if (defined $old_sig{$signal} && $old_sig{$signal} ne 'DEFAULT') {
            $SIG{$signal} = $old_sig{$signal};
        }
        else {
            $SIG{$signal} = 'DEFAULT';
        }

        $self->term->Attribs->{catch_signals} = 0;

        $self->term->free_line_state();
        $self->term->cleanup_after_signal();
        kill $signal, $$;
        $self->term->Attribs->{catch_signals} = 1;
        return 1;
    };

    # The WINCH signal handler.
    # Tell ReadLine to resize the terminal.
    my $winch_handler = sub {
        $self->term->resize_terminal;
        $last_signal = $_[0];
        $old_sig{$_[0]}->(@_) if ref $old_sig{$_[0]};
        return 1;
    };

    # The CONT signal handler.
    # In case we get suspended, make sure we redraw the CLI on wake-up.
    my $cont_handler = sub {
        $last_signal = $_[0];

        $self->term->free_line_state();
        $self->term->cleanup_after_signal();

        $old_sig{$_[0]}->(@_) if ref $old_sig{$_[0]};

        $self->term->Attribs->{line_buffer} = '';
        $self->term->reset_after_signal();
        $self->term->forced_update_display();
        return 1;
    };

    # Install signal handler(s).
    my $install_handlers = sub {
        $self->term->Attribs->{catch_signals} = 1;

        $SIG{WINCH} = $winch_handler;
        $SIG{CONT} = $cont_handler;
        $SIG{HUP}
            = $SIG{INT}
            = $SIG{QUIT}
            = $SIG{ALRM}
            #= $SIG{STOP}
            = $SIG{TERM}
            = $SIG{TTIN}
            = $SIG{TTOU}
            = $SIG{TSTP}
                = $generic_handler;

    };

    $install_handlers->();

    # Post-signal hook, called by ReadLine.
    #
    # Abort the current input line, except when the
    # WINCH signal was received.
    #
    $self->term->Attribs->{signal_event_hook} = sub {
        return 1 if $last_signal eq 'WINCH'; # Nothing on WINCH.

        # Move to a new line and clear input buffer.
        $self->term->crlf();
        $self->term->Attribs->{line_buffer} = '';
        $self->term->forced_update_display();

        $install_handlers->(); # Re-install handlers, if necessary.
        $self->term->reset_after_signal();
        return 1;
    };

    return %old_sig;
}


# See POD X<readline>
sub readline {
    my ($self, %args) = @_;

    my $prompt = $args{prompt} // $self->prompt;
    my $skip   = exists $args{skip} ? $args{skip} : $self->skip;

    $self->_set_completion_attribs;
    my %old_sig = $self->_set_signal_handlers;

    my $input;
    while (defined ($input = $self->term->readline($prompt))) {
        next if defined $skip && $input =~ $skip;
        last;
    }

    %SIG = %old_sig; # Restore signal handlers.
    return $input;
}


sub read_history {
    my $self = shift;

    my $hist_file = @_ ? shift @_ : $self->history_file;

    if ($self->term->ReadHistory($hist_file)) {
        $self->history_file($hist_file);
        $self->set_error('');
        return 1;
    }
    else {
        return $self->set_error("$hist_file: $!");
    }
}


sub write_history {
    my $self = shift;

    my $hist_file = @_ ? shift @_ : $self->history_file;

    if ($self->term->WriteHistory($hist_file)) {
        $self->history_file($hist_file);
        $self->set_error('');
        return 1;
    }
    else {
        return $self->set_error("$hist_file: $!");
    }
}


sub execute {
    my ($self, $cmd) = @_;

    my ($error, @cmd) = $self->_split_line($cmd);

    my %args = (
        status       => 0,
        error        => '',
        command_line => $cmd,
        command_path => [$self],
        unparsed     => \@cmd,
        options      => {},
        arguments    => [],
    );

    return $self->try_callback(%args, status => -1, error => $error)
        if length $error;

    if (@cmd == 0) {
        $args{error} = loc("missing command");
        $args{status} = -1;
    }
    elsif (my $cmd_ref = $self->find_command($cmd[0])) {
        %args = $cmd_ref->execute(%args,
            unparsed => [@cmd[1..$#cmd]]
        );
    }
    else {
        $args{error} = $self->error;
        $args{status} = -1;
    }

    return $self->try_callback(%args);
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI - CLI interpreter based on Term::ReadLine

=head1 VERSION

version 0.051007

=head1 SYNOPSIS

 use Term::CLI;
 use Term::CLI::Command;
 use Term::CLI::Argument::Filename;
 use Data::Dumper;

 my $cli = Term::CLI->new(
    name => 'myapp',
    prompt => 'myapp> ',
    callback => sub {
        my ($self, %args) = @_;
        print Data::Dumper->Dump([\%args], ['args']);
        return %args;
    },
    commands => [
        Term::CLI::Command->new(
            name => 'copy',
            options => [ 'verbose!' ],
            arguments => [
                Term::CLI::Argument::Filename->new(name => 'src'),
                Term::CLI::Argument::Filename->new(name => 'dst'),
            ],
            callback => sub {
                my ($self, %args) = @_;
                print Data::Dumper->Dump([\%args], ['args']);
                return (%args, status => 0);
            }
        )
    ],
 );

 $cli->read_history;  # Read history from ~/.myapp_history
 $cli->write_history; # Write history to ~/.myapp_history

 $cli->word_delimiters(';,');
 # $cli will now recognise things like: 'copy;--verbose;a,b'

 $cli->word_delimiters(" \t\n");
 # $cli will now recognise things like: 'copy --verbose a b'

 while ( my $input = $cli->readline(skip => qr/^\s*(?:#.*)?$/) ) {
    $cli->execute($input);
 }

=head1 DESCRIPTION

Implement an easy-to-use command line interpreter based on
L<Term::ReadLine>(3p) and L<Term::ReadLine::Gnu>(3p).

First-time users may want to read L<Term::CLI::Tutorial>(3p)
and L<Term::CLI::Intro>(3p) first, and peruse the example
scripts in the source distribution's F<examples> and
F<tutorial> directories.

=head1 CLASS STRUCTURE

=head2 Inherits from:

L<Term::CLI::Base>(3p).

=head2 Consumes:

L<Term::CLI::Role::CommandSet>(3p).

=head1 CONSTRUCTORS

=over

=item B<new> ( B<attr> => I<VAL> ... )
X<new>

Create a new C<Term::CLI> object and return a reference to it.

Valid attributes:

=over

=item B<callback> =E<gt> I<CodeRef>

Reference to a subroutine that should be called when the command
is executed, or C<undef>.

=item B<commands> =E<gt> I<ArrayRef>

Reference to an array containing L<Term::CLI::Command> object
instances that describe the commands that C<Term::CLI> recognises,
or C<undef>.

=item B<name> =E<gt> I<Str>

The application name. This is used for e.g. the history file
and default command prompt.

If not given, defaults to C<$FindBin::Script> (see L<FindBin>(3p)).

=item B<prompt> =E<gt> I<Str>

Prompt to display when L<readline|/readline> is called. Defaults
to the application name with C<E<gt>> and a space appended.

=item B<skip> =E<gt> I<RegEx>

Set the object's L<skip|/skip> attribute, telling the
L<readline|/readline> method to ignore input lines
that match the given I<RegEx>.
A common call value is C<qr{^\s+(?:#.*)$}> to skip
empty lines, lines with only whitespace, and comments.

=item B<history_file> =E<gt> I<Str>

Specify the file to read/write input history to/from.
The default is I<name> + C<_history> in the user's
I<HOME> directory.

=item B<history_lines> =E<gt> I<Str>

Maximum number of lines to keep in the input history.
Default is 1000.

=back

=back

=head1 INHERITED METHODS

This class inherits all the attributes and accessors of
L<Term::CLI::Role::CommandSet>(3p) and L<Term::CLI::Base>(3p),
most notably:

=head2 Accessors

=over

=item B<has_callback>
X<has_callback>

See
L<has_callback in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/has_callback>.

=item B<has_commands>
X<has_commands>

See
L<has_commands in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/has_commands>.

=item B<commands> ( [ I<ArrayRef> ] )
X<commands>

See
L<commands in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/commands>.

I<ArrayRef> with C<Term::CLI::Command> object instances.

=item B<callback> ( [ I<CodeRef> ] )
X<callback>

See
L<callback in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/callback>.

=back

=head2 Others

=over

=item B<find_command> ( I<Str> )
X<find_command>

See
L<find_command in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/find_command>.

=item B<find_matches> ( I<Str> )
X<find_matches>

See
L<find_matches in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/find_matches>.

=back

=head1 METHODS

=head2 Accessors

=over

=item B<name>
X<name>

The application name. 
See
L<name in Term::CLI::Base|Term::CLI::Base/name>.

=item B<prompt> ( [ I<Str> ] )
X<prompt>

Get or set the command line prompt to display to the user.

=item B<term>
X<term>

Return a reference to the underlying L<Term::CLI::ReadLine> object.
See
L<term in Term::CLI::Base|Term::CLI::Base/term>.

=item B<quote_characters> ( [ I<Str> ] )
X<quote_characters>

Get or set the characters that should considered quote characters
for the completion and parsing/execution routines.

Default is C<'">, that is a single quote or a double quote.

It's possible to change this, but this will interfere with the default
splitting function, so if you do want custom quote characters, you should
also override the L<split_function|/split_function>.

=item B<split_function> ( [ I<CodeRef> ] )

Get or set the function that is used to split a (partial) command
line into words. The default function uses
L<Text::ParseWords::parse_line|Text::ParseWords/parse_line>.
Note that this implies that it can take into account custom delimiters,
but I<not custom quote characters>.

The I<CodeRef> is called as:

    ( ERROR, [ WORD, ... ] ) = CodeRef->( CLI_OBJ, TEXT )

The function should return a list of at least one element, an
I<ERROR> string. Subsequent elements are the words resulting
from the split.

I<ERROR> string should be empty (not C<undef>!) if splitting
was successful, otherwise it should contain a relevant error
message.

=item B<word_delimiters> ( [ I<Str> ] )

Get or set the characters that are considered word delimiters
in the completion and parsing/execution routines.

Default is C< \t\n>, that is I<space>, I<tab>, and I<newline>.

The first character in the string is also the character that is
appended to a completed word at the command line prompt.

=back

=head2 History Control

=over

=item B<history_lines> ( [ I<Int> ] )

Get or set the maximum number of lines to keep in the history.
Default is 1000.

=item B<history_file> ( [ I<Str> ] )

Set the default file to read from/write to.

=item B<read_history> ( [ I<Str> ] )

Try to read input history from the L<history_file()|/history_file>.
Returns 1 on success. On failure, it will set the L<error|/error>
field and return C<undef>.

If I<Str> is given, it will try to read from that file instead. If that is
successful, the L<history_file()|/history_file> attribute will be set
to I<Str>.

=item B<write_history> ( [ I<Str> ] )

Try to write the input history to the L<history_file()|/history_file>.
Returns 1 on success. On failure, it will set the L<error|/error> field
and return C<undef>.

If I<Str> is given, it will try to write to that file instead. If that is
successful, the L<history_file()|/history_file> attribute will be set
to I<Str>.

=back

=head2 Others

=over

=item B<complete_line> ( I<TEXT>, I<LINE>, I<START> )
X<complete_line>

Called when the user hits the I<TAB> key for completion.

I<TEXT> is the text to complete, I<LINE> is the input line so
far, I<START> is the position in the line where I<TEXT> starts.

The function will split the line in words and delegate the
completion to the first L<Term::CLI::Command> sub-command,
see L<Term::CLI::Command|Term::CLI::Command/complete_line>.

=item B<readline> ( [ I<ATTR> =E<gt> I<VAL>, ... ] )
X<readline>

Read a line from the input connected to L<term|/term>, using
the L<Term::ReadLine> interface.

By default, it returns the line read from the input, or
an empty value if end of file has been reached (e.g.
the user hitting I<Ctrl-D>).

The following I<ATTR> are recognised:

=over

=item B<skip> =E<gt> I<RegEx>

Override the object's L<skip|/skip> attribute.

Skip lines that match the I<RegEx> parameter. A common
call is:

    $text = CLI->readline( skip => qr{^\s+(?:#.*)$} );

This will skip empty lines, lines containing whitespace, and
comments.

=item B<prompt> =E<gt> I<Str>

Override the prompt given by the L<prompt|/prompt> method.

=back

Examples:

    # Just read the next input line.
    $line = $cli->readline;
    exit if !defined $line;

    # Skip empty lines and comments.
    $line = $cli->readline( skip => qr{^\s*(?:#.*)?$} );
    exit if !defined $line;

=item B<execute> ( I<Str> )
X<execute>

Parse and execute the command line consisting of I<Str>
(see the return value of L<readline|/readline> above).

The command line is split into words using
the L<split_function|/split_function>.
If that succeeds, then the resulting list of words is
parsed and executed, otherwise a parse error is generated
(i.e. the object's L<callback|Term::CLI::Role::CommandSet/callback>
function is called with a C<status> of C<-1> and a suitable C<error>
field).

For specifying a custom word splitting method, see
L<split_function|/split_function>.

Example:

    while (my $line = $cli->readline(skip => qr/^\s*(?:#.*)?$/)) {
        $cli->execute($line);
    }

The command line is parsed depth-first, and for every
L<Term::CLI::Command>(3p) encountered, that object's
L<callback|Term::CLI::Role::CommandSet/callback> function
is executed (see
L<callback in Term::CLI::Role::Command|Term::CLI::Role::CommandSet/callback>).

=over

=item *

Suppose that the C<file> command has a C<show> sub-command that takes
an optional C<--verbose> option and a single file argument.

=item *

Suppose the input is:

    file show --verbose foo.txt

=item *

Then the parse tree looks like this:

    (cli-root)
        |
        +--> Command 'file'
                |
                +--> Command 'show'
                        |
                        +--> Option '--verbose'
                        |
                        +--> Argument 'foo.txt'

=item *

Then the callbacks will be called in the following order:

=over

=item 1.

Callback for 'show'

=item 2.

Callback for 'file'

=item 3.

Callback for C<Term::CLI> object.

=back

The return value from each L<callback|Term::CLI::Role::CommandSet/callback>
(a hash in list form) is fed into the next callback function in the
chain. This allows for adding custom data to the return hash that will
be fed back up the parse tree (and eventually to the caller).

=back

=back

=head1 SIGNAL HANDLING

The C<Term::CLI> object sets its own signal handlers in the L<readline|/readline>
function.

The signal handlers will ensure the terminal is in a sane state.


The following signal handlers discard the the current input line, restore
any previous signal handler, and re-throw the signal:
C<HUP>, C<INT>, C<QUIT>, C<ALRM>, C<TERM>, C<TTIN>, C<TTOU>, C<TSTP>.

The C<CONT> and C<WINCH> signals are treated slightly different: they don't
re-throw the signal, but rather just call any previous signal handler. The
C<WINCH> signal handler will not discard the input line.

It also makes sure that after a keyboard suspend (C<TSTP>) and
subsequent continue (C<CONT>), the command prompt is redrawn:

    bash$ perl tutorial/term_cli.pl
    > foo
    > ^Z
    [1]+  Stopped                 perl tutorial/term_cli.pl
    bash$ fg
    perl tutorial/term_cli.pl
    > _

=head1 SEE ALSO

L<FindBin>(3p),
L<Getopt::Long>(3p),
L<Term::CLI>(3p),
L<Term::CLI::Argument>(3p),
L<Term::CLI::Command>(3p),
L<Term::CLI::Intro>(3p),
L<Term::CLI::Role::CommandSet>(3p),
L<Term::CLI::Tutorial>(3p),
L<Text::ParseWords>(3p),
L<Types::Standard>(3p).

Inspiration for the custom completion came from:
L<https://robots.thoughtbot.com/tab-completion-in-gnu-readline>.
This is an excellent tutorial into the completion mechanics
of the C<readline> library, and, by extension,
L<Term::ReadLine::Gnu>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>, 2018.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Steven Bakker

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=begin __PODCOVERAGE

=head1 THIS SECTION SHOULD BE HIDDEN

This section is meant for methods that should not be considered
for coverage. This typically includes things like BUILD and DEMOLISH from
Moo/Moose. It is possible to skip these when using the Pod::Coverage class
(using C<also_private>), but this is not an option when running C<cover>
from the command line.

The simplest trick is to add a hidden section with an item list containing
these methods.

=over

=item BUILD

=item DEMOLISH

=back

=end __PODCOVERAGE

=cut
