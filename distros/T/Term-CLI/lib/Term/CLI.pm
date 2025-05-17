#=============================================================================
#
#       Module:  Term::CLI
#
#  Description:  Class for CLI parsing
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  31/01/18
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

package Term::CLI 0.061000;

use 5.014;
use warnings;

use Text::ParseWords 3.27 qw( parse_line );
use Term::CLI::ReadLine;
use FindBin 1.50;
use File::Which 1.09;

use Term::CLI::L10N qw( loc );

use List::Util qw( first );

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

my @PAGERS = (
    [   qw(
            less --no-lessopen --no-init
            --dumb --quit-at-eof
            --quit-if-one-screen
            --RAW-CONTROL-CHARS
        )
    ],
    ['more'],
    ['pg'],
);

use Moo 1.000001;
use namespace::clean 0.25;

extends 'Term::CLI::Base';

with qw(
    Term::CLI::Role::CommandSet
    Term::CLI::Role::State
);

my $DFL_HIST_SIZE = 1000;

# Provide a default for 'name'.
has '+name' => ( default => sub {$FindBin::Script} );

has 'pager' => (
    is      => 'rw',
    isa     => ArrayRef [Str],
    default => sub {
        first { defined which( $_->[0] ) } @PAGERS;
    },
);

has cleanup => (
    is        => 'rw',
    isa       => Maybe [CodeRef],
    predicate => 1
);

has prompt => (
    is      => 'rw',
    isa     => Str,
    default => sub {'~> '}
);

has split_function => (
    is      => 'rw',
    isa     => CodeRef,
    default => sub { \&_default_split }
);

has skip => (
    is  => 'rw',
    isa => RegexpRef,
);

has history_file => (
    is  => 'rw',
    isa => Str
);

has history_lines => (
    is      => 'rw',
    isa     => Int,
    default => sub {$DFL_HIST_SIZE},
    trigger => 1,
);

has word_delimiters  => ( is => 'rw', isa => Str, default => sub {" \n\t"} );
has quote_characters => ( is => 'rw', isa => Str, default => sub {q("')} );

sub BUILD {
    my ( $self, $args ) = @_;

    my @fh_list = ( \*STDIN, \*STDOUT );
    if (exists $args->{filehandles}) {
        @fh_list = @{ $args->{filehandles} // [] };
    }

    my $term = Term::CLI::ReadLine->new( $self->name, @fh_list );

    if ( my $sig_list = $args->{ignore_keyboard_signals} ) {
        $term->ignore_keyboard_signals( @{$sig_list} );
    }

    $term->Attribs->{char_is_quoted_p} = sub { $self->_is_escaped(@_) };

    $self->_set_completion_attribs;

    if ( !exists $args->{callback} ) {
        $self->callback( \&_default_callback );
    }

    if ( !exists $args->{history_file} ) {
        my $hist_file = $self->name;
        $hist_file =~ s{^/}{}gx;
        $hist_file =~ s{/$}{}gx;
        $hist_file =~ s{/+}{-}gx;
        $self->history_file("$::ENV{HOME}/.${hist_file}_history");
    }

    # Ensure that the history_lines trigger is called.
    # If history_lines is given as a parameter, the trigger
    # *is* called, but it happens *before* the `$term` is
    # initialised; and if no history_lines is given, the
    # trigger is not called for the default.
    $self->history_lines( $self->history_lines );
    return;
}

sub DEMOLISH {
    my ($self) = @_;
    if ( $self->has_cleanup ) {
        $self->cleanup->($self);
    }
    return;
}

sub _trigger_history_lines {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $self, $arg ) = @_;

    # Terminal may not be initialiased yet...
    return if !$self->term;

    $self->term->StifleHistory($arg);
    return;
}

# %args = $self->_default_callback(%args);
#
# Default top-level callback if none is given.
# Simply check the status and print an error
# message if status < 0.
sub _default_callback {
    my ( $self, %args ) = @_;

    if ( $args{status} < 0 ) {
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
    my ( $self, $text ) = @_;

    my $delim = $self->word_delimiters;

    $text =~ s/^ [$delim]+ //gxsm; # Strip leading delimiters.

    return (q{}) if length $text == 0; # Blank line.

    my @words = parse_line( qr{ [$delim]+ }xms, 0, $text );

    return ( loc('unbalanced quotes in input') ) if !@words;

    # If the text ends in one or more delimiters, the last word will be
    # "undef", but it's not an errror, so just eliminate it.
    if ( @words > 0 && !defined $words[-1] ) {
        pop @words;
    }
    return ( q{}, @words );
}

sub unescape_input {
    my ($self, $text, $quote_char) = @_;

    if ( !$quote_char || $quote_char ne q{'} ) {
        return $text =~ s{ \\ (.) }{$1}xgr;
    }
    return $text;
}

sub escape_input {
    my ($self, $text, $quote_char) = @_;

    if ( !$quote_char ) {
        my $delim = $self->root_node->word_delimiters;
        return $text =~ s{ ([$delim\'\"\\]) }{\\$1}xgr;
    }
    if ( $quote_char ne q{'}) {
        return $text =~ s{ ([$quote_char\\]) }{\\$1}xgr;
    }
    return $text;
}

# BOOL = CLI->_is_escaped($line, $index);
#
# The character at $index in $line is a possible word break
# character. Check if it is perhaps escaped.
#
sub _is_escaped {
    my ( $self, $line, $index ) = @_;
    return 0 if not defined $index or $index <= 0;
    return 0 if substr( $line, $index - 1, 1 ) ne q{\\};
    return !$self->_is_escaped( $line, $index - 1 );
}

sub read_history {
    my ( $self, $hist_file ) = @_;

    $hist_file //= $self->history_file;

    $self->term->ReadHistory($hist_file)
        or return $self->set_error("$hist_file: $!");
    $self->history_file($hist_file);
    $self->clear_error;
    return 1;
}

sub write_history {
    my ( $self, $hist_file ) = @_;

    $hist_file //= $self->history_file;

    $self->term->WriteHistory($hist_file)
        or return $self->set_error("$hist_file: $!");
    $self->history_file($hist_file);
    $self->clear_error;
    return 1;
}

sub write_pager {
    my ($self, %args) = @_;

    my $pager_cmd = $self->pager // [];

    my $text =
        ref $args{text} eq 'ARRAY'
            ? join( q{}, @{ $args{text} } )
            : $args{text};

    if (@$pager_cmd) {
        no warnings 'exec';    ## no critic (ProhibitNoWarnings)
        local ( $SIG{PIPE} ) = 'IGNORE';    # Temporarily avoid accidents.

        my $pager_fh;
        if (! open $pager_fh, '|-', @{$pager_cmd}) {
            $args{status} = -1;
            $args{error} =
                loc( "cannot run '[_1]': [_2]", $$pager_cmd[0], $! );
            return %args;
        }

        print $pager_fh $text;
        $pager_fh->close;

        $args{status} = $?;
        $args{error}  = $! if $args{status} != 0;
        return %args;
    }

    my $pager_fh;
    if (! open $pager_fh, '>&', \*STDOUT) {
        $args{status} = -1;
        $args{error}  = "cannot dup STDOUT: $!";
        return %args;
    }
    print $pager_fh $text;
    if ( !$pager_fh->close ) {
        $args{status} = -1;
        $args{error}  = $!;
    }
    return %args;
}

1;

__END__

=pod

=head1 NAME

Term::CLI - CLI interpreter based on Term::ReadLine

=head1 VERSION

version 0.061000

=head1 SYNOPSIS

 use Term::CLI;
 use Term::CLI::Command;
 use Term::CLI::Argument::Filename;
 use Data::Dumper;

 my $cli = Term::CLI->new(
    name => 'myapp',
    prompt => 'myapp> ',
    cleanup => sub {
        my ($cli) = @_;
        $cli->write_history;
            or warn "cannot write history: ".$cli->error."\n";
    },
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
    $cli->execute_line($input);
 }

=head1 DESCRIPTION

Implement an easy-to-use command line interpreter based on
L<Term::ReadLine>(3p). Although primarily aimed at use with
the L<Term::ReadLine::Gnu>(3p) implementation, it also supports
L<Term::ReadLine::Perl>(3p).

First-time users may want to read L<Term::CLI::Tutorial>(3p)
and L<Term::CLI::Intro>(3p) first, and peruse the example
scripts in the source distribution's F<examples> and
F<tutorial> directories.

=head2 I/O handles

By default B<Term::CLI> will create a
L<Term::CLI::ReadLine|Term::CLI::ReadLine> object
(which creates a L<Term::ReadLine|Term::ReadLine> object)
that reads from F<STDIN> and writes to F<STDOUT>.

This is notably different from the default behaviour of e.g.
GNU Readline which opens the TTY separately. This may cause
unexpected behaviour in case of UTF-8 I/O.

By explicitly specifying F<STDIN> and F<STDOUT> as the I/O
handles, we force the underlying readline implementation to
use the same I/O encoding as the standard I/O handles. This
means that e.g. C<use open qw(:std :utf8)> will do what you
expect and enable UTF-8 input/output.

See the C<filehandles> argument to L<new|/new> below for information
on how to change this.

=head1 CLASS STRUCTURE

=head2 Inherits from:

L<Term::CLI::Base>(3p).

=head2 Consumes:

L<Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet>(3p),
L<Term::CLI::Role::State|Term::CLI::Role::State>(3p).

=head1 CONSTRUCTORS

=over

=item B<new> ( B<attr> => I<VAL> ... )
X<new>

Create a new B<Term::CLI> object and return a reference to it.

Valid attributes:

=over

=item B<callback> =E<gt> I<CodeRef>

Reference to a subroutine that should be called when the command
is executed, or C<undef>.

=item B<filehandles> =E<gt> I<ArrayRef>

File handles to use for input and output, resp. The array can be:

    undef
    [ ]
    [ IN_FH, OUT_FH ]

If the value is either C<undef> or an empty list, then we rely
on the underlying readline's implementation to determine the
I/O handles (but see L<IE<sol>O handles|/I/O handles> above).

=item B<cleanup> =E<gt> I<CodeRef>

Reference to a subroutine that should be called when the object
is destroyed (i.e. in L<Moo> terminology, when C<DEMOLISH> is called).

=item B<commands> =E<gt> I<ArrayRef>

Reference to an array containing L<Term::CLI::Command> object
instances that describe the commands that B<Term::CLI> recognises,
or C<undef>.

=item B<ignore_keyboard_signals> =E<gt> I<ArrayRef>

Specify a list of signals for which the keyboard generation should be
turned off during a C<readline> operation.

The list of signals should be a combination of C<INT>, C<QUIT>, or
C<TSTP>. See also
L<ignore_keyboard_signals|Term::CLI::ReadLine/ignore_keyboard_signals>
in L<Term::CLI::ReadLine>(3p). If this is not specified, C<QUIT>
keyboard generation is turned off by default.

=item B<name> =E<gt> I<Str>

The application name. This is used for e.g. the history file
and default command prompt.

If not given, defaults to C<$FindBin::Script> (see L<FindBin>(3p)).

=item B<pager> =E<gt> I<ArrayRef>[I<Str>]

The C<pager> attribute is used by L<write_pager()|/write_pager>.

The value should be a command line split on words, e.g.:

    OBJ->pager( [ 'cat', '-n', '-e' ] );

If an empty list is provided, no external pager will
be used, and output is printed to F<STDOUT> directly.

See also the L<pager|/pager> method.

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

=item B<history_lines> =E<gt> I<Int>

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

=item B<callback> ( [ I<CodeRef> ] )
X<callback>

See
L<callback in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/callback>.

=item B<has_commands>
X<has_commands>

See
L<has_commands in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/has_commands>.

=item B<commands> ( [ I<ArrayRef> ] )
X<commands>

See
L<commands in Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/commands>.

I<ArrayRef> with B<Term::CLI::Command> object instances.

=back

=head2 Others

=over

=item B<has_cleanup>
X<has_cleanup>

Predicate function that returns whether or not the C<cleanup> attribute has been set.

=item B<cleanup> ( [ I<CodeRef> ] )

Gets or sets a reference to a subroutine that should be called when the object
is destroyed (i.e. in L<Moo> terminology, when C<DEMOLISH> is called).

The code is called with one parameter: the object to be destroyed. One typical
use of C<cleanup> is to ensure that the history gets saved upon exit:

  my $cli = Term::CLI->new(
    ...
    cleanup => sub {
      my ($cli) = @_;
      $cli->write_history
        or warn "cannot write history: ".$cli->error."\n";
    }
  );

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

=item B<pager> ( [ I<ArrayRef>[I<Str>] ] )
X<pager>

Get or set the pager to use for L<write_pager()|/write_pager>.

If an empty list is provided, no external pager will
be used, and output is printed to F<STDOUT> directly.

Example:

    $help_cmd->pager([]); # Print directly to STDOUT.
    $help_cmd->pager([ 'cat', '-n' ]); # Number output lines.

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


=head2 Input Control

The L<split_function|/split_function> has already been described
above.
However, we also need to deal with escape sequences in
(partial) input that may or may not be quoted.

For word splitting this is handled by the
L<split_function|/split_function>,
but for command/argument completion we need to make sure the text
passed to the completion functions is the "proper" text.

For example:

  $ ls foo\ b<TAB>

The completion mechanism will be asked to complete C<foo\ b>.
However, since the string is unquoted, what we really want to complete
is C<foo b>. On the other hand, with:

  $ ls 'foo\ b<TAB>

We would want to run completion on the literal C<foo\ b> (because it
is single-quoted).

For this, we use L<unescape_input>.
Then, when completion is done, we run L<escape_input> on the results.

=over

=item B<escape_input>
X<escape_input>

=item B<unescape_input>
X<unescape_input>

    $ESCAPED = $CLI->escape_input( $INPUT, $QUOTE_CHAR );
    $UNESCAPED = $CLI->unescape_input( $INPUT, $QUOTE_CHAR );

Add or remove backslash escape sequences in an input string.
This is used during command and argument completion.
I<$INPUT> is the string to operate on,
I<$QUOTE_CHAR> indicates how the input is quoted (if any);
if I<$QUOTE_CHAR> is I<undef> or an empty string,
then the I<$INPUT> is not surrounded by quotes.
Otherwise,
I<$QUOTE_CHAR> indicates which quotes are being used
(C<"> or C<'>).

The B<unescape_input> is called right before word completion:

  INPUT      | CALL                                   | RESULT
  -----------|----------------------------------------|--------------
  <foo\ b>   | $CLI->unescape_input(q{foo\ b}, undef) | q{foo b}
  <"foo\ b>  | $CLI->unescape_input(q{foo\ b}, q{"})  | q{foo b}
  <'foo\ b>  | $CLI->unescape_input(q{foo\ b}, q{'})  | q{foo\ b}

The result is then run through the completion process,
after which B<escape_input> is called on the result(s):

  INPUT      | CALL                                   | RESULT
  -----------|----------------------------------------|--------------
  <foo\ bar> | $CLI->escape_input(q{foo\ bar}, undef) | q{foo\\\ bar}
  <foo\ bar> | $CLI->escape_input(q{foo\ bar}, q{"})  | q{foo\\ bar}
  <foo\ bar> | $CLI->escape_input(q{foo\ bar}, q{'})  | q{foo\ bar}

The default functions do the following:

                | UNESCAPE               | ESCAPE
  --------------|------------------------|-----------------
  unquoted      | anything preceded by \ | \, space, quote
  double quote  | anything preceded by \ | \, double quote
  single quote  | nothing                | nothing

If you need special treatment,
you will have to sub-class B<Term::CLI> and overload these methods.

=back

=head2 Output Control

=over

=item B<write_pager>
X<write_pager>

    %status = $CLI->write_pager( text => TEXT, ... );

Output the I<TEXT> through the L<pager|/pager> command, or
F<STDOUT> if the C<pager> attribute is not set.

Returns the arguments it was given with the following fields set if
there was an error:

=over

=item C<status> =E<gt> I<Int>

Non-zero value indicates an error.

=item C<error> =E<gt> I<Str>

Erorr diagnostic.

=back

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

=head1 SIGNAL HANDLING

The B<Term::CLI> object (through L<Term::CLI::ReadLine>) will make sure that
signals are handled "correctly". This especially means that if a signal is
not ignored, the terminal is left in a "sane" state before any signal
handler is called or the program exits.

See also
L<SIGNAL HANDLING in Term::CLI::ReadLine|Term::CLI::ReadLine/SIGNAL HANDLING>.

=head1 SEE ALSO

L<FindBin>(3p),
L<Moo>(3p),
L<Getopt::Long>(3p),
L<Term::CLI::Argument>(3p),
L<Term::CLI::Base>(3p),
L<Term::CLI::Command>(3p),
L<Term::CLI::Intro>(3p),
L<Term::CLI::ReadLine>(3p),
L<Term::CLI::Role::CommandSet>(3p),
L<Term::CLI::Tutorial>(3p),
L<Term::ReadLine::Gnu>(3p),
L<Term::ReadLine::Perl>(3p),
L<Term::ReadLine>(3p),
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
