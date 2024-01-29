# NAME

Term::CLI - CLI interpreter based on Term::ReadLine

# SYNOPSIS

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

# DESCRIPTION

Implement an easy-to-use command line interpreter based on
[Term::ReadLine](https://metacpan.org/pod/Term%3A%3AReadLine)(3p). Although primarily aimed at use with
the [Term::ReadLine::Gnu](https://metacpan.org/pod/Term%3A%3AReadLine%3A%3AGnu)(3p) implementation, it also supports
[Term::ReadLine::Perl](https://metacpan.org/pod/Term%3A%3AReadLine%3A%3APerl)(3p).

First-time users may want to read [Term::CLI::Tutorial](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ATutorial)(3p)
and [Term::CLI::Intro](https://metacpan.org/pod/Term%3A%3ACLI%3A%3AIntro)(3p) first, and peruse the example
scripts in the source distribution's `examples` and
`tutorial` directories.

## I/O handles

By default `Term::CLI` will create a
[Term::CLI::ReadLine](https://metacpan.org/pod/Term%3A%3ACLI%3A%3AReadLine) object
(which creates a [Term::ReadLine](https://metacpan.org/pod/Term%3A%3AReadLine) object)
that reads from `STDIN` and writes to `STDOUT`.

This is notably different from the default behaviour of e.g.
GNU Readline which opens the TTY separately. This may cause
unexpected behaviour in case of UTF-8 I/O.

By explicitly specifying `STDIN` and `STDOUT` as the I/O
handles, we force the underlying readline implementation to
use the same I/O encoding as the standard I/O handles. This
means that e.g. `use open qw(:std :utf8)` will do what you
expect and enable UTF-8 input/output.

See the `filehandles` argument to [new](#new) below for information
on how to change this.

# CLASS STRUCTURE

## Inherits from:

[Term::CLI::Base](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ABase)(3p).

## Consumes:

[Term::CLI::Role::CommandSet](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ARole%3A%3ACommandSet)(3p),
[Term::CLI::Role::State](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ARole%3A%3AState)(3p).

# CONSTRUCTORS

- **new** ( **attr** => _VAL_ ... )


    Create a new `Term::CLI` object and return a reference to it.

    Valid attributes:

    - **callback** => _CodeRef_

        Reference to a subroutine that should be called when the command
        is executed, or `undef`.

    - **filehandles** => _ArrayRef_

        File handles to use for input and output, resp. The array can be:

            undef
            [ ]
            [ IN_FH, OUT_FH ]

        If the value is either `undef` or an empty list, then we rely
        on the underlying readline's implementation to determine the
        I/O handles (but see [I/O handles](#i-o-handles) above).

    - **cleanup** => _CodeRef_

        Reference to a subroutine that should be called when the object
        is destroyed (i.e. in [Moo](https://metacpan.org/pod/Moo) terminology, when `DEMOLISH` is called).

    - **commands** => _ArrayRef_

        Reference to an array containing [Term::CLI::Command](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ACommand) object
        instances that describe the commands that `Term::CLI` recognises,
        or `undef`.

    - **ignore\_keyboard\_signals** => _ArrayRef_

        Specify a list of signals for which the keyboard generation should be
        turned off during a `readline` operation.

        The list of signals should be a combination of `INT`, `QUIT`, or
        `TSTP`. See also
        [ignore\_keyboard\_signals](https://metacpan.org/pod/Term%3A%3ACLI%3A%3AReadLine#ignore_keyboard_signals)
        in [Term::CLI::ReadLine](https://metacpan.org/pod/Term%3A%3ACLI%3A%3AReadLine)(3p). If this is not specified, `QUIT`
        keyboard generation is turned off by default.

    - **name** => _Str_

        The application name. This is used for e.g. the history file
        and default command prompt.

        If not given, defaults to `$FindBin::Script` (see [FindBin](https://metacpan.org/pod/FindBin)(3p)).

    - **pager** => _ArrayRef_\[_Str_\]

        The `pager` attribute is used by [write\_pager()](#write_pager).

        The value should be a command line split on words, e.g.:

            OBJ->pager( [ 'cat', '-n', '-e' ] );

        If an empty list is provided, no external pager will
        be used, and output is printed to `STDOUT` directly.

        See also the [pager](#pager) method.

    - **prompt** => _Str_

        Prompt to display when [readline](#readline) is called. Defaults
        to the application name with `>` and a space appended.

    - **skip** => _RegEx_

        Set the object's [skip](#skip) attribute, telling the
        [readline](#readline) method to ignore input lines
        that match the given _RegEx_.
        A common call value is `qr{^\s+(?:#.*)$}` to skip
        empty lines, lines with only whitespace, and comments.

    - **history\_file** => _Str_

        Specify the file to read/write input history to/from.
        The default is _name_ + `_history` in the user's
        _HOME_ directory.

    - **history\_lines** => _Int_

        Maximum number of lines to keep in the input history.
        Default is 1000.

# INHERITED METHODS

This class inherits all the attributes and accessors of
[Term::CLI::Role::CommandSet](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ARole%3A%3ACommandSet)(3p) and [Term::CLI::Base](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ABase)(3p),
most notably:

## Accessors

- **has\_callback**


    See
    [has\_callback in Term::CLI::Role::CommandSet](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ARole%3A%3ACommandSet#has_callback).

- **callback** ( \[ _CodeRef_ \] )


    See
    [callback in Term::CLI::Role::CommandSet](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ARole%3A%3ACommandSet#callback).

- **has\_commands**


    See
    [has\_commands in Term::CLI::Role::CommandSet](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ARole%3A%3ACommandSet#has_commands).

- **commands** ( \[ _ArrayRef_ \] )


    See
    [commands in Term::CLI::Role::CommandSet](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ARole%3A%3ACommandSet#commands).

    _ArrayRef_ with `Term::CLI::Command` object instances.

## Others

- **has\_cleanup**


    Predicate function that returns whether or not the `cleanup` attribute has been set.

- **cleanup** ( \[ _CodeRef_ \] )

    Gets or sets a reference to a subroutine that should be called when the object
    is destroyed (i.e. in [Moo](https://metacpan.org/pod/Moo) terminology, when `DEMOLISH` is called).

    The code is called with one parameter: the object to be destroyed. One typical
    use of `cleanup` is to ensure that the history gets saved upon exit:

        my $cli = Term::CLI->new(
          ...
          cleanup => sub {
            my ($cli) = @_;
            $cli->write_history
              or warn "cannot write history: ".$cli->error."\n";
          }
        );

- **find\_command** ( _Str_ )


    See
    [find\_command in Term::CLI::Role::CommandSet](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ARole%3A%3ACommandSet#find_command).

- **find\_matches** ( _Str_ )


    See
    [find\_matches in Term::CLI::Role::CommandSet](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ARole%3A%3ACommandSet#find_matches).

# METHODS

## Accessors

- **name**


    The application name.
    See
    [name in Term::CLI::Base](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ABase#name).

- **pager** ( \[ _ArrayRef_\[_Str_\] \] )


    Get or set the pager to use for [write\_pager()](#write_pager).

    If an empty list is provided, no external pager will
    be used, and output is printed to `STDOUT` directly.

    Example:

        $help_cmd->pager([]); # Print directly to STDOUT.
        $help_cmd->pager([ 'cat', '-n' ]); # Number output lines.

- **prompt** ( \[ _Str_ \] )


    Get or set the command line prompt to display to the user.

- **term**


    Return a reference to the underlying [Term::CLI::ReadLine](https://metacpan.org/pod/Term%3A%3ACLI%3A%3AReadLine) object.
    See
    [term in Term::CLI::Base](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ABase#term).

- **quote\_characters** ( \[ _Str_ \] )


    Get or set the characters that should considered quote characters
    for the completion and parsing/execution routines.

    Default is `'"`, that is a single quote or a double quote.

    It's possible to change this, but this will interfere with the default
    splitting function, so if you do want custom quote characters, you should
    also override the [split\_function](#split_function).

- **split\_function** ( \[ _CodeRef_ \] )

    Get or set the function that is used to split a (partial) command
    line into words. The default function uses
    [Text::ParseWords::parse\_line](https://metacpan.org/pod/Text%3A%3AParseWords#parse_line).
    Note that this implies that it can take into account custom delimiters,
    but _not custom quote characters_.

    The _CodeRef_ is called as:

        ( ERROR, [ WORD, ... ] ) = CodeRef->( CLI_OBJ, TEXT )

    The function should return a list of at least one element, an
    _ERROR_ string. Subsequent elements are the words resulting
    from the split.

    _ERROR_ string should be empty (not `undef`!) if splitting
    was successful, otherwise it should contain a relevant error
    message.

- **word\_delimiters** ( \[ _Str_ \] )

    Get or set the characters that are considered word delimiters
    in the completion and parsing/execution routines.

    Default is ` \t\n`, that is _space_, _tab_, and _newline_.

    The first character in the string is also the character that is
    appended to a completed word at the command line prompt.

## Output Control

- **write\_pager**


        %status = $CLI->write_pager( text => TEXT, ... );

    Output the _TEXT_ through the [pager](#pager) command, or
    `STDOUT` if the `pager` attribute is not set.

    Returns the arguments it was given with the following fields set if
    there was an error:

    - `status` => _Int_

        Non-zero value indicates an error.

    - `error` => _Str_

        Erorr diagnostic.

## History Control

- **history\_lines** ( \[ _Int_ \] )

    Get or set the maximum number of lines to keep in the history.
    Default is 1000.

- **history\_file** ( \[ _Str_ \] )

    Set the default file to read from/write to.

- **read\_history** ( \[ _Str_ \] )

    Try to read input history from the [history\_file()](#history_file).
    Returns 1 on success. On failure, it will set the [error](#error)
    field and return `undef`.

    If _Str_ is given, it will try to read from that file instead. If that is
    successful, the [history\_file()](#history_file) attribute will be set
    to _Str_.

- **write\_history** ( \[ _Str_ \] )

    Try to write the input history to the [history\_file()](#history_file).
    Returns 1 on success. On failure, it will set the [error](#error) field
    and return `undef`.

    If _Str_ is given, it will try to write to that file instead. If that is
    successful, the [history\_file()](#history_file) attribute will be set
    to _Str_.

# SIGNAL HANDLING

The `Term::CLI` object (through [Term::CLI::ReadLine](https://metacpan.org/pod/Term%3A%3ACLI%3A%3AReadLine)) will make sure that
signals are handled "correctly". This especially means that if a signal is
not ignored, the terminal is left in a "sane" state before any signal
handler is called or the program exits.

See also
[SIGNAL HANDLING in Term::CLI::ReadLine](https://metacpan.org/pod/Term%3A%3ACLI%3A%3AReadLine#SIGNAL-HANDLING).

# SEE ALSO

[FindBin](https://metacpan.org/pod/FindBin)(3p),
[Moo](https://metacpan.org/pod/Moo)(3p),
[Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)(3p),
[Term::CLI::Argument](https://metacpan.org/pod/Term%3A%3ACLI%3A%3AArgument)(3p),
[Term::CLI::Base](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ABase)(3p),
[Term::CLI::Command](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ACommand)(3p),
[Term::CLI::Intro](https://metacpan.org/pod/Term%3A%3ACLI%3A%3AIntro)(3p),
[Term::CLI::ReadLine](https://metacpan.org/pod/Term%3A%3ACLI%3A%3AReadLine)(3p),
[Term::CLI::Role::CommandSet](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ARole%3A%3ACommandSet)(3p),
[Term::CLI::Tutorial](https://metacpan.org/pod/Term%3A%3ACLI%3A%3ATutorial)(3p),
[Term::ReadLine::Gnu](https://metacpan.org/pod/Term%3A%3AReadLine%3A%3AGnu)(3p),
[Term::ReadLine::Perl](https://metacpan.org/pod/Term%3A%3AReadLine%3A%3APerl)(3p),
[Term::ReadLine](https://metacpan.org/pod/Term%3A%3AReadLine)(3p),
[Text::ParseWords](https://metacpan.org/pod/Text%3A%3AParseWords)(3p),
[Types::Standard](https://metacpan.org/pod/Types%3A%3AStandard)(3p).

Inspiration for the custom completion came from:
[https://robots.thoughtbot.com/tab-completion-in-gnu-readline](https://robots.thoughtbot.com/tab-completion-in-gnu-readline).
This is an excellent tutorial into the completion mechanics
of the `readline` library, and, by extension,
[Term::ReadLine::Gnu](https://metacpan.org/pod/Term%3A%3AReadLine%3A%3AGnu)(3p).

# AUTHOR

Steven Bakker <sbakker@cpan.org>, 2018.

# COPYRIGHT AND LICENSE

Copyright (c) 2018 Steven Bakker

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
